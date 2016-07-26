//
//  main.m
//  test
//
//  Created by miaoyou.gmy on 14/11/6.
//  Copyright (c) 2014年 miaoyou.gmy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "AppDelegate.h"

#import <pthread.h>
#import <libkern/OSAtomic.h>
pthread_mutex_t lock;
OSSpinLock spinlock;
const int MAXLIMIT = 10000;
static size_t const iterations = 10;
extern uint64_t dispatch_benchmark(size_t count, void (^block)(void));
int main(int argc, char * argv[]) {
    static int count = 0;
    
    {
        count = 0;
        uint64_t t = dispatch_benchmark(iterations, ^{
            NSOperationQueue *queue = [[NSOperationQueue alloc] init];
            queue.maxConcurrentOperationCount = 10;
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
        
        NSLog(@"Avg. RunTime: %llu μs",t/1000);
    }
    
    /*
    {
        count = 0;
        uint64_t t = dispatch_benchmark(iterations, ^{
        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        NSObject *obj = [NSObject new];
        queue.maxConcurrentOperationCount = 10;
        NSMutableArray *operationArr = [NSMutableArray arrayWithCapacity:10];
        for(int i=0;i<10;i++){
                NSBlockOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:^{
                    for(int i=0;i<MAXLIMIT;i++){
                        @synchronized (obj) {
                            ++count;
                        }
                    }
                    
                }];
            
                [operationArr addObject:blockOperation];
            }
            [queue addOperations:operationArr waitUntilFinished:YES];
            NSLog(@"count = %d",count);
        });
    
        NSLog(@"synchronized Avg. RunTime: %llu μs",t/1000);
    }
    
    
    {
        count = 0;
        uint64_t t = dispatch_benchmark(iterations, ^{
        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        NSLock *lock = [NSLock new];
        queue.maxConcurrentOperationCount = 10;
        NSMutableArray *operationArr = [NSMutableArray arrayWithCapacity:10];
        for(int i=0;i<10;i++){
            
            NSBlockOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:^{
                for(int i=0;i<MAXLIMIT;i++){
                    [lock lock];
                    ++count;
                    [lock unlock];
                }
                
            }];
            
            [operationArr addObject:blockOperation];
        }
        [queue addOperations:operationArr waitUntilFinished:YES];
            NSLog(@"count = %d",count);
    });
    
        NSLog(@"NSLock Avg. RunTime: %llu μs",t/1000);
    }
    
    
    {
        count = 0;
        uint64_t t = dispatch_benchmark(iterations, ^{
        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        

        pthread_mutexattr_t attr;
        pthread_mutexattr_init(&attr);
        pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE);
        pthread_mutex_init(&lock, &attr);
        pthread_mutexattr_destroy(&attr);

        queue.maxConcurrentOperationCount = 10;
        NSMutableArray *operationArr = [NSMutableArray arrayWithCapacity:10];
        for(int i=0;i<10;i++){
            
            NSBlockOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:^{
                for(int i=0;i<MAXLIMIT;i++){
                    pthread_mutex_lock(&lock);
                    ++count;
                    pthread_mutex_unlock(&lock);
                }
                
            }];
            
            [operationArr addObject:blockOperation];
        }
            [queue addOperations:operationArr waitUntilFinished:YES];
            NSLog(@"count = %d",count);
        });
    
        NSLog(@"pthread_mutex_lock Avg. RunTime: %llu μs",t/1000);
    }
    
    
    {
        count = 0;
        uint64_t t = dispatch_benchmark(iterations, ^{
            NSOperationQueue *queue = [[NSOperationQueue alloc] init];
            
            dispatch_semaphore_t lock = dispatch_semaphore_create(1);
            
            queue.maxConcurrentOperationCount = 10;
            NSMutableArray *operationArr = [NSMutableArray arrayWithCapacity:10];
            for(int i=0;i<10;i++){
                
                NSBlockOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:^{
                    for(int i=0;i<MAXLIMIT;i++){
                        dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
                        ++count;
                        dispatch_semaphore_signal(lock);
                    }
                    
                }];
                
                [operationArr addObject:blockOperation];
            }
            [queue addOperations:operationArr waitUntilFinished:YES];
            NSLog(@"count = %d",count);
        });
        
        NSLog(@"dispatch_semaphore Avg. RunTime: %llu μs",t/1000);
    }
    
    {
        count = 0;
        uint64_t t = dispatch_benchmark(iterations, ^{
            NSOperationQueue *queue = [[NSOperationQueue alloc] init];
            
            spinlock = OS_SPINLOCK_INIT;
            
            queue.maxConcurrentOperationCount = 10;
            NSMutableArray *operationArr = [NSMutableArray arrayWithCapacity:10];
            for(int i=0;i<10;i++){
                
                NSBlockOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:^{
                    for(int i=0;i<MAXLIMIT;i++){
                        OSSpinLockLock(&spinlock);
                        ++count;
                        OSSpinLockUnlock(&spinlock);
                    }
                    
                }];
                
                [operationArr addObject:blockOperation];
            }
            [queue addOperations:operationArr waitUntilFinished:YES];
            NSLog(@"count = %d",count);
        });
        
        NSLog(@"OSSpinLock Avg. RunTime: %llu μs",t/1000);
    }
     */
}
