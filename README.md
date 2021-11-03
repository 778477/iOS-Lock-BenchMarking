# iOS 中各个锁的性能比较  

在多线程编程中，为了保证原子性操作。我们经常会使用到锁。

为了 验证锁的重要性。 我们先构造一下不正规多线程的案发现场，笔者这里使用的是`NSOperationQueue` 来调度10个线程 `NSBlockOperation`

我们先看一下 基准将线程池中的`maxConcurrentOperationCount`最大并发数调整为1。串行看一下结果。

```

const int MAXLIMIT = 10000;
static size_t const iterations = 10;
extern uint64_t dispatch_benchmark(size_t count, void (^block)(void));
int main(int argc, char * argv[]) {
    static int count = 0;
    
    uint64_t t = dispatch_benchmark(iterations, ^{
        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        queue.maxConcurrentOperationCount = 1;
        NSMutableArray *operationArr = [NSMutableArray arrayWithCapacity:10];
        for(int i=0;i<10;i++){
            
            NSBlockOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:^{
                
                for(int i=0;i<MAXLIMIT;i++){
                        ++count;
                }
                
            }];
            
            [operationArr addObject:blockOperation];
        }
        [queue addOperations:operationArr waitUntilFinished:YES];
        NSLog(@"count = %d",count);
    });
    
    NSLog(@"Avg. RunTime: %llu ms",t/(1000*1000));
}


```
串行执行10个线程任务。 计算结果正确 耗时为 `1736 μs`

```
2016-07-26 21:09:24.389 test[17179:6645892] count = 100000
2016-07-26 21:09:24.391 test[17179:6645892] count = 200000
2016-07-26 21:09:24.392 test[17179:6645892] count = 300000
2016-07-26 21:09:24.394 test[17179:6645892] count = 400000
2016-07-26 21:09:24.395 test[17179:6645892] count = 500000
2016-07-26 21:09:24.396 test[17179:6645892] count = 600000
2016-07-26 21:09:24.397 test[17179:6645892] count = 700000
2016-07-26 21:09:24.398 test[17179:6645892] count = 800000
2016-07-26 21:09:24.399 test[17179:6645892] count = 900000
2016-07-26 21:09:24.400 test[17179:6645892] count = 1000000
2016-07-26 21:09:24.400 test[17179:6645892] Avg. RunTime: 1736 μs
```


然后，我们把 最大并发数修改为10，没错 10个线程火力全开

```
2016-07-26 21:11:31.416 test[17196:6647532] count = 76012
2016-07-26 21:11:31.418 test[17196:6647532] count = 154651
2016-07-26 21:11:31.419 test[17196:6647532] count = 225008
2016-07-26 21:11:31.420 test[17196:6647532] count = 300892
2016-07-26 21:11:31.421 test[17196:6647532] count = 377298
2016-07-26 21:11:31.421 test[17196:6647532] count = 431631
2016-07-26 21:11:31.423 test[17196:6647532] count = 531631
2016-07-26 21:11:31.424 test[17196:6647532] count = 631631
2016-07-26 21:11:31.425 test[17196:6647532] count = 713271
2016-07-26 21:11:31.426 test[17196:6647532] count = 781313
2016-07-26 21:11:31.426 test[17196:6647532] Avg. RunTime: 1784 μs
```

答案是错的。这个就是我们要的多线程错误使用现场。

下面，我们将使用以下这些 锁来做实验。观察一下性能 (测试设备为 iPhone 6 iOS 9.3.2)

 1. `@synchronized`
 2. `NSLock`
 3. `pthread_mutex_lock`
 4. `dispatch_semaphore`
 5. `OSSpinLock`

 
 
 
 ```
2016-07-26 21:09:24.389 test[17179:6645892] count = 100000
2016-07-26 21:09:24.391 test[17179:6645892] count = 200000
2016-07-26 21:09:24.392 test[17179:6645892] count = 300000
2016-07-26 21:09:24.394 test[17179:6645892] count = 400000
2016-07-26 21:09:24.395 test[17179:6645892] count = 500000
2016-07-26 21:09:24.396 test[17179:6645892] count = 600000
2016-07-26 21:09:24.397 test[17179:6645892] count = 700000
2016-07-26 21:09:24.398 test[17179:6645892] count = 800000
2016-07-26 21:09:24.399 test[17179:6645892] count = 900000
2016-07-26 21:09:24.400 test[17179:6645892] count = 1000000
2016-07-26 21:09:24.400 test[17179:6645892] Avg. RunTime: 1736 μs
2016-07-26 21:09:24.436 test[17179:6645892] count = 100000
2016-07-26 21:09:24.486 test[17179:6645892] count = 200000
2016-07-26 21:09:25.536 test[17179:6645892] count = 300000
2016-07-26 21:09:25.657 test[17179:6645892] count = 400000
2016-07-26 21:09:25.713 test[17179:6645892] count = 500000
2016-07-26 21:09:25.794 test[17179:6645892] count = 600000
2016-07-26 21:09:25.858 test[17179:6645892] count = 700000
2016-07-26 21:09:25.968 test[17179:6645892] count = 800000
2016-07-26 21:09:26.000 test[17179:6645892] count = 900000
2016-07-26 21:09:26.097 test[17179:6645892] count = 1000000
2016-07-26 21:09:26.097 test[17179:6645892] synchronized Avg. RunTime: 169721 μs
2016-07-26 21:09:26.194 test[17179:6645892] count = 100000
2016-07-26 21:09:26.745 test[17179:6645892] count = 200000
2016-07-26 21:09:26.884 test[17179:6645892] count = 300000
2016-07-26 21:09:27.022 test[17179:6645892] count = 400000
2016-07-26 21:09:27.116 test[17179:6645892] count = 500000
2016-07-26 21:09:27.253 test[17179:6645892] count = 600000
2016-07-26 21:09:27.477 test[17179:6645892] count = 700000
2016-07-26 21:09:28.474 test[17179:6645892] count = 800000
2016-07-26 21:09:29.352 test[17179:6645892] count = 900000
2016-07-26 21:09:30.426 test[17179:6645892] count = 1000000
2016-07-26 21:09:30.426 test[17179:6645892] NSLock Avg. RunTime: 432829 μs
2016-07-26 21:09:30.847 test[17179:6645892] count = 100000
2016-07-26 21:09:31.152 test[17179:6645892] count = 200000
2016-07-26 21:09:31.480 test[17179:6645892] count = 300000
2016-07-26 21:09:31.888 test[17179:6645892] count = 400000
2016-07-26 21:09:32.903 test[17179:6645892] count = 500000
2016-07-26 21:09:33.907 test[17179:6645892] count = 600000
2016-07-26 21:09:34.916 test[17179:6645892] count = 700000
2016-07-26 21:09:35.313 test[17179:6645892] count = 800000
2016-07-26 21:09:35.728 test[17179:6645892] count = 900000
2016-07-26 21:09:36.014 test[17179:6645892] count = 1000000
2016-07-26 21:09:36.014 test[17179:6645892] pthread_mutex_lock Avg. RunTime: 558792 μs
2016-07-26 21:09:36.023 test[17179:6645892] count = 100000
2016-07-26 21:09:36.039 test[17179:6645892] count = 200000
2016-07-26 21:09:36.048 test[17179:6645892] count = 300000
2016-07-26 21:09:36.075 test[17179:6645892] count = 400000
2016-07-26 21:09:36.084 test[17179:6645892] count = 500000
2016-07-26 21:09:36.093 test[17179:6645892] count = 600000
2016-07-26 21:09:36.102 test[17179:6645892] count = 700000
2016-07-26 21:09:36.111 test[17179:6645892] count = 800000
2016-07-26 21:09:36.119 test[17179:6645892] count = 900000
2016-07-26 21:09:36.128 test[17179:6645892] count = 1000000
2016-07-26 21:09:36.129 test[17179:6645892] dispatch_semaphore Avg. RunTime: 11468 μs
2016-07-26 21:09:36.135 test[17179:6645892] count = 100000
2016-07-26 21:09:36.140 test[17179:6645892] count = 200000
2016-07-26 21:09:36.144 test[17179:6645892] count = 300000
2016-07-26 21:09:36.150 test[17179:6645892] count = 400000
2016-07-26 21:09:36.157 test[17179:6645892] count = 500000
2016-07-26 21:09:36.163 test[17179:6645892] count = 600000
2016-07-26 21:09:36.170 test[17179:6645892] count = 700000
2016-07-26 21:09:36.175 test[17179:6645892] count = 800000
2016-07-26 21:09:36.181 test[17179:6645892] count = 900000
2016-07-26 21:09:36.187 test[17179:6645892] count = 1000000
2016-07-26 21:09:36.187 test[17179:6645892] OSSpinLock Avg. RunTime: 5848 μs


 ```
 
 
 
 
 ![](https://raw.githubusercontent.com/778477/iOS-Lock-BenchMarking/master/benchmark.png)

`pthread_mutex_lock > NSLock > synchronized > dispatch_semaphore > OSSpinLock`

实际真机测试结果：我们常用的 `@synchronized` 表现不赖。表现最好的是 `OSSpinLock 自旋锁`。 

不过部分开发者发现 自旋锁不再安全。 这里引用一下具体原因：


> 新版 iOS 中，系统维护了 5 个不同的线程优先级/QoS: background，utility，default，user-initiated，user-interactive。高优先级线程始终会在低优先级线程前执行，一个线程不会受到比它更低优先级线程的干扰。这种线程调度算法会产生潜在的优先级反转问题，从而破坏了 spin lock。

> 具体来说，如果一个低优先级的线程获得锁并访问共享资源，这时一个高优先级的线程也尝试获得这个锁，它会处于 spin lock 的忙等状态从而占用大量 CPU。此时低优先级线程无法与高优先级线程争夺 CPU 时间，从而导致任务迟迟完不成、无法释放 lock。这并不只是理论上的问题，libobjc 已经遇到了很多次这个问题了，于是苹果的工程师停用了 OSSpinLock。

> 苹果工程师 Greg Parker 提到，对于这个问题，一种解决方案是用 truly unbounded backoff 算法，这能避免 livelock 问题，但如果系统负载高时，它仍有可能将高优先级的线程阻塞数十秒之久；另一种方案是使用 handoff lock 算法，这也是 libobjc 目前正在使用的。锁的持有者会把线程 ID 保存到锁内部，锁的等待者会临时贡献出它的优先级来避免优先级反转的问题。理论上这种模式会在比较复杂的多锁条件下产生问题，但实践上目前还一切都好。

> libobjc 里用的是 Mach 内核的 thread_switch() 然后传递了一个 mach thread port 来避免优先级反转，另外它还用了一个私有的参数选项，所以开发者无法自己实现这个锁。另一方面，由于二进制兼容问题，OSSpinLock 也不能有改动。

> 最终的结论就是，除非开发者能保证访问锁的线程全部都处于同一优先级，否则 iOS 系统中所有类型的自旋锁都不能再使用了。



