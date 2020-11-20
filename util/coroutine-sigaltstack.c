/*
 * Win32 coroutine initialization code
 *
 * Copyright (c) 2011 Kevin Wolf <kwolf@redhat.com>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#include "qemu/osdep.h"
#include "qemu-common.h"
#include "qemu/coroutine_int.h"

typedef struct
{
    Coroutine base;
    CoroutineAction action;
} CoroutineWin32;

static __thread CoroutineWin32 leader;
static __thread Coroutine *current;

struct CoroContext {
	pthread_mutex_t mutex;
	pthread_cond_t cond;
	Coroutine *current;
};

static __thread struct CoroContext *CoroContext;
static __thread pthread_t the_thread;

static void coroutine_trampoline(Coroutine *co_);

static void SwitchToFiber(Coroutine *fiber)
{
	assert(CoroContext != NULL);
	struct CoroContext *cc = CoroContext;
	pthread_mutex_lock(&cc->mutex);
	while (cc->current) {
		pthread_cond_wait(&cc->cond, &cc->mutex);
	}
	cc->current = fiber;
	pthread_cond_signal(&cc->cond);
	pthread_mutex_unlock(&cc->mutex);

#if 1
	while (true) {
		int should_break = 0;
		pthread_mutex_lock(&cc->mutex);
		should_break = (cc->current == NULL);
		pthread_mutex_unlock(&cc->mutex);
		if (should_break) {
			break;
		}
		sleep(1);
	}
#endif
}

static void *CoroThread(void *arg)
{
	struct CoroContext *cc = (struct CoroContext*)arg;
	while (true) 
	{
		pthread_mutex_lock(&cc->mutex);
		while (!cc->current) {
			pthread_cond_wait(&cc->cond, &cc->mutex);
		}
		if (cc->current) {
			coroutine_trampoline(cc->current);
			cc->current = NULL;
		}
		pthread_cond_signal(&cc->cond);
		pthread_mutex_unlock(&cc->mutex);
	}
	return NULL;
}

/* This function is marked noinline to prevent GCC from inlining it
 * into coroutine_trampoline(). If we allow it to do that then it
 * hoists the code to get the address of the TLS variable "current"
 * out of the while() loop. This is an invalid transformation because
 * the SwitchToFiber() call may be called when running thread A but
 * return in thread B, and so we might be in a different thread
 * context each time round the loop.
 */
CoroutineAction __attribute__((noinline))
qemu_coroutine_switch(Coroutine *from_, Coroutine *to_,
                      CoroutineAction action)
{
    CoroutineWin32 *from = DO_UPCAST(CoroutineWin32, base, from_);
    CoroutineWin32 *to = DO_UPCAST(CoroutineWin32, base, to_);

	printf("%s: from e=%p to e=%p action=%d in_coro=%d\n", __func__, from_->entry, to_->entry, action, !CoroContext);
	to->action = action;

	if (CoroContext) {
		SwitchToFiber(to_);
	}
	else {
		current = to_;
		Coroutine tmp = {};
		memmove(&tmp, to_, sizeof(Coroutine));
		memmove(to_, from_, sizeof(Coroutine));
		memmove(from_, &tmp, sizeof(Coroutine));
	}
    return from->action ? from->action : COROUTINE_TERMINATE;
}

static void __attribute__((noinline)) coroutine_trampoline(Coroutine *co_)
{
    Coroutine *co = co_;
	printf("%s: co->entry=%p arg=%p\n", __func__,
			co ? co->entry : NULL, co ? co->entry_arg : NULL);

    while (true) {
		CoroutineWin32 *con = DO_UPCAST(CoroutineWin32, base, co);
		current = co;
		printf("%s: call co->entry=%p arg=%p ns=%d\n", __func__,
				co ? co->entry : NULL, co ? co->entry_arg : NULL, con->action);
		if (co->entry) {
			co->entry(co->entry_arg);
		}
		if (co->caller) {
			CoroutineAction ca = qemu_coroutine_switch(co, co->caller, COROUTINE_TERMINATE);
			printf("%s: return action %d\n", __func__, ca);

			//if (ca != COROUTINE_ENTER) {
				break;
			//}
		}
		if (!co->entry) {
			break;
		}
    }
}

Coroutine *qemu_coroutine_new(void)
{
    CoroutineWin32 *co;

    co = g_malloc0(sizeof(*co));
	co->action = COROUTINE_YIELD;

	qemu_coroutine_self();
	
	if (!CoroContext) {
		CoroContext = g_malloc0(sizeof(*CoroContext));
		pthread_cond_init(&CoroContext->cond, NULL);
		pthread_mutex_init(&CoroContext->mutex, NULL);

		pthread_attr_t tattr;
		pthread_attr_init(&tattr);
		pthread_attr_setstacksize(&tattr, COROUTINE_STACK_SIZE);
		pthread_create(&the_thread, &tattr, CoroThread, CoroContext);
		sleep(1);
	}
    return &co->base;
}

void qemu_coroutine_delete(Coroutine *co_)
{
    CoroutineWin32 *co = DO_UPCAST(CoroutineWin32, base, co_);
    g_free(co);
}

Coroutine *qemu_coroutine_self(void)
{
    if (!current) {
        current = &leader.base;
		leader.action = COROUTINE_TERMINATE;
    }
    return current;
}

bool qemu_in_coroutine(void)
{
	qemu_coroutine_self();
    return current && current != &leader.base;
}
