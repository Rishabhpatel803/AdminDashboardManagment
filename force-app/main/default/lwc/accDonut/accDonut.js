import { LightningElement, api } from "lwc";

/** Ring geometry in viewBox units (which are px at natural size). */
const RADIUS = 52;
const CIRCUMFERENCE = 2 * Math.PI * RADIUS;

/** ~2px of surface showing between touching segments, never a stroke. */
const SEGMENT_GAP = 3;

const ARC_COLOR = {
  healthy: "#2e844a",
  warning: "#fe9339",
  critical: "#ea001e",
  info: "#0176d3"
};

/**
 * accDonut - the single donut primitive behind all four rings on the page
 * (License Utilization, Access Health, Integration Health, Test Coverage).
 *
 * Two modes:
 *   value    - a single 0-100 gauge arc over a track.
 *   segments - [{ id, value, status }] parts-of-a-whole, separated by a
 *              surface gap rather than a border.
 */
export default class AccDonut extends LightningElement {
  /** 0-100. Ignored when `segments` is supplied. */
  @api value = 0;
  /** Overrides the centre text. Defaults to the rounded percentage. */
  @api valueLabel;
  /** Small line under the centre value, e.g. "Good", "Test Coverage". */
  @api sublabel;
  /** healthy | warning | critical | info - drives the arc colour. */
  @api status = "info";
  /** Outer diameter in px. */
  @api size = 108;
  /** Ring thickness in px. */
  @api thickness = 13;
  /** Parts-of-a-whole segments. */
  @api segments;
  /** Native tooltip - carries the underlying maths. */
  @api tooltip;

  get isSegmented() {
    return Array.isArray(this.segments) && this.segments.length > 0;
  }

  get arcColor() {
    return ARC_COLOR[this.status] || ARC_COLOR.info;
  }

  get clampedValue() {
    const num = Number(this.value) || 0;
    return Math.min(100, Math.max(0, num));
  }

  /** One entry per drawn arc, each pre-styled so the template stays declarative. */
  get arcs() {
    if (this.isSegmented) {
      const total = this.segments.reduce(
        (sum, s) => sum + (Number(s.value) || 0),
        0
      );
      if (total <= 0) return [];

      const gapped = this.segments.length > 1;
      let offset = 0;

      return this.segments.map((segment, index) => {
        const length = ((Number(segment.value) || 0) / total) * CIRCUMFERENCE;
        const visible = gapped ? Math.max(length - SEGMENT_GAP, 1) : length;
        const arc = {
          key: segment.id || `segment-${index}`,
          style: this.arcStyle(
            ARC_COLOR[segment.status] || ARC_COLOR.info,
            visible,
            offset
          )
        };
        offset += length;
        return arc;
      });
    }

    const length = (this.clampedValue / 100) * CIRCUMFERENCE;
    return [{ key: "value", style: this.arcStyle(this.arcColor, length, 0) }];
  }

  arcStyle(color, visibleLength, offset) {
    const remainder = Math.max(CIRCUMFERENCE - visibleLength, 0);
    return `stroke:${color};stroke-dasharray:${visibleLength.toFixed(2)} ${remainder.toFixed(2)};stroke-dashoffset:${(-offset).toFixed(2)};`;
  }

  get rootStyle() {
    return `width:${this.size}px;height:${this.size}px;--acc-donut-thickness:${this.thickness}px;`;
  }

  get valueStyle() {
    return `font-size:${Math.round(this.size * 0.2)}px;`;
  }

  get displayValue() {
    return this.valueLabel || `${Math.round(this.clampedValue)}%`;
  }

  /** Identity is never colour-alone: the ring always has a text equivalent. */
  get assistiveLabel() {
    return this.sublabel
      ? `${this.displayValue} ${this.sublabel}`
      : this.displayValue;
  }
}
