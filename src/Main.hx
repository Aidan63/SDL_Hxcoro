import SDL;
import cpp.marshal.RootHandle;
import haxe.Exception;
import haxe.coro.schedulers.IScheduler;
import haxe.coro.dispatchers.IDispatchObject;
import haxe.coro.dispatchers.Dispatcher;
import hxcoro.Coro.*;
import hxcoro.CoroRun;
import hxcoro.task.ICoroNode;
import hxcoro.schedulers.EventLoopScheduler;

@:coroutine function coroEntry(node:ICoroNode) {
	trace("It works!");
	delay(1000);
	trace("It still works!");
}

private class SdlDispatcher extends Dispatcher {
	final id : Int;
	final s : EventLoopScheduler;

	public function new(id, s) {
		this.id = id;
		this.s  = s;
	}

	public function dispatch(obj:IDispatchObject) {
		final event = new Event();
		event.type = id;
		event.user.data1 = RootHandle.create(obj).toVoidPointer();

		SDL.pushEvent(event);
	}

	function get_scheduler():IScheduler {
		return s;
	}
}

function main() {
	SDL.init(SDL.INIT_VIDEO);

	final window           = SDL.createWindow("SDL Test", 1280, 720, SDL.WINDOW_RESIZABLE);
	final eventIds         = SDL.registerEvents(2);
	final schedulerEventId = eventIds;
	final dispatchEventId  = eventIds + 1;

	final scheduler  = new EventLoopScheduler();
	final dispatcher = new SdlDispatcher(dispatchEventId, scheduler);

	final schedulerEvent = new Event();
	schedulerEvent.type = eventIds;
	if (false == SDL.pushEvent(schedulerEvent)) {
		throw new Exception("Failed to push scheduler event");
	}

	final coroTask = CoroRun.with(dispatcher).create(coroEntry);
	coroTask.start();
	
	var run = true;
	
	final event = new Event();
	while (run) {
		while (SDL.pollEvent(event)) {
			switch event.type {
				case SDL.EVENT_QUIT:
					run = false;
				case id if (id == schedulerEventId):
					scheduler.run();

					if (false == SDL.pushEvent(schedulerEvent)) {
						throw new Exception("Failed to push scheduler event");
					}
				case id if (id == dispatchEventId):
					final root = RootHandle.fromVoidPointer(event.user.data1);

					final obj : IDispatchObject = root.getObject();

					root.close();

					obj.onDispatch();
				case _:
					//
			}
		}
	}

	SDL.destroyWindow(window);
	SDL.quit();
}
