/// <reference types="pixi.js" /> 
/**
 * @type {typeof import("pixi.js")}
 */
const PIXI = window.PIXI;
export class World extends PIXI.Container {
    constructor(app) {
        super();
        //this.lastPosition = { x: 0, y: 0 }
        this.isDragging = false;
        this.eventMode = 'static';
        this.hitArea = app.screen;
        this.cursor = 'pointer'
        this   
             .on('pointerdown', this.onDragStart)
             .on('pointerup', this.onDragEnd)
             .on('pointerleave', this.onDragEnd);

    }

    onDragStart() {
        this.isDragging = true;
        this.cursor = 'grabbing';
        this.on('pointermove', this.onDragMove);
        this.alpha = 0.5;
    }

    onDragEnd() {
        if (this.isDragging) {
            this.isDragging = false;
            this.cursor = 'pointer'
            this.off('pointermove', this.onDragMove);
            this.alpha = 1;
        }
    }

    onDragMove(e) {
        if (!this.isDragging) return
        this.parent.toLocal(e.global, null, this.position)
    }

}