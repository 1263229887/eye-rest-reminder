export namespace main {
	
	export class AppState {
	    enabled: boolean;
	    resting: boolean;
	    activeKind: string;
	    activeName: string;
	    remaining: number;
	    progress: number;
	    message: string;
	    shortRemaining: number;
	    shortTotal: number;
	    longRemaining: number;
	    longTotal: number;
	    nextName: string;
	    nextSeconds: number;
	
	    static createFrom(source: any = {}) {
	        return new AppState(source);
	    }
	
	    constructor(source: any = {}) {
	        if ('string' === typeof source) source = JSON.parse(source);
	        this.enabled = source["enabled"];
	        this.resting = source["resting"];
	        this.activeKind = source["activeKind"];
	        this.activeName = source["activeName"];
	        this.remaining = source["remaining"];
	        this.progress = source["progress"];
	        this.message = source["message"];
	        this.shortRemaining = source["shortRemaining"];
	        this.shortTotal = source["shortTotal"];
	        this.longRemaining = source["longRemaining"];
	        this.longTotal = source["longTotal"];
	        this.nextName = source["nextName"];
	        this.nextSeconds = source["nextSeconds"];
	    }
	}
	export class ReminderSettings {
	    shortIntervalMinutes: number;
	    shortDurationSeconds: number;
	    longIntervalMinutes: number;
	    longDurationMinutes: number;
	
	    static createFrom(source: any = {}) {
	        return new ReminderSettings(source);
	    }
	
	    constructor(source: any = {}) {
	        if ('string' === typeof source) source = JSON.parse(source);
	        this.shortIntervalMinutes = source["shortIntervalMinutes"];
	        this.shortDurationSeconds = source["shortDurationSeconds"];
	        this.longIntervalMinutes = source["longIntervalMinutes"];
	        this.longDurationMinutes = source["longDurationMinutes"];
	    }
	}

}

