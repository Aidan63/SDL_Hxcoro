import SDL;
import cpp.marshal.RootHandle;
import haxe.coro.schedulers.IScheduleObject;
import hxcoro.task.ICoroNode;
import hxcoro.Coro.*;
import hxcoro.CoroRun;
import hxcoro.schedulers.EventLoopScheduler;
import hxcoro.dispatchers.IDispatcher;
import haxe.Exception;

@:coroutine function coroEntry(node:ICoroNode) {
	trace("It works!");
	delay(1000);
	trace("It still works!");
}

private class SdlDispatcher implements IDispatcher {
	final id : Int;

	public function new(id) {
		this.id = id;
	}

	public function dispatch(obj:IScheduleObject) {
		final event = new Event();
		event.type = id;
		event.user.data1 = RootHandle.create(obj).toVoidPointer();

		SDL.pushEvent(event);
	}
}

function main() {
	SDL.init(SDL.INIT_VIDEO);

	final window           = SDL.createWindow("SDL Test", 1280, 720, SDL.WINDOW_RESIZABLE);
	final eventIds         = SDL.registerEvents(2);
	final schedulerEventId = eventIds;
	final dispatchEventId  = eventIds + 1;

	final dispatcher = new SdlDispatcher(dispatchEventId);
	final scheduler  = new EventLoopScheduler(dispatcher);

	final schedulerEvent = new Event();
	schedulerEvent.type = eventIds;
	if (false == SDL.pushEvent(schedulerEvent)) {
		throw new Exception("Failed to push scheduler event");
	}

	final coroTask = CoroRun.with(scheduler).create(coroEntry);
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

					final obj : IScheduleObject = root.getObject();

					root.close();

					obj.onSchedule();
				case _:
					//
			}
		}
	}

	SDL.destroyWindow(window);
	SDL.quit();
}
