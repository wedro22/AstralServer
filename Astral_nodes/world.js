/// <reference types="pixi.js" /> 
/**
 * @type {typeof import("pixi.js")}
 */
const PIXI = window.PIXI;
export class World extends PIXI.Container {
    constructor(app) {
        super();
        this.app = app;
        this.lastPosition = { x: 0, y: 0 };
        this.app.stage.eventMode = 'static';
        this.app.stage.hitArea = this.app.screen;
        this.app.stage.cursor = 'pointer';
        this.app.stage.on('pointerdown', this.onDragStart, this);
    }

    onDragStart(e) {
        this.lastPosition = e.global.clone();
        this.app.stage.cursor = 'grabbing';
        this.alpha = 0.5;
        this.app.stage.on('pointermove', this.onDragMove, this);
        this.app.stage.on('pointerup', this.onDragEnd, this);
        this.app.stage.on('pointerleave', this.onDragEnd, this);
    }

    onDragEnd() {
        this.app.stage.cursor = 'pointer';
        this.alpha = 1;
        this.app.stage.off('pointermove', this.onDragMove, this);
        this.app.stage.off('pointerup', this.onDragEnd, this);
        this.app.stage.off('pointerleave', this.onDragEnd, this);
    }

    onDragMove(e) {
        const delta = { x: e.x - this.lastPosition.x, y: e.y - this.lastPosition.y };
        this.x += delta.x;
        this.y += delta.y;
        this.lastPosition = e.global.clone();
    }

}