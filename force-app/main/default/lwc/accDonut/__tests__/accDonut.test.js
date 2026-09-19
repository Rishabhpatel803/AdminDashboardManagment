import { createElement } from "lwc";
import AccDonut from "c/accDonut";

const CIRCUMFERENCE = 2 * Math.PI * 52;

function build(props = {}) {
  const element = createElement("c-acc-donut", { is: AccDonut });
  Object.assign(element, props);
  document.body.appendChild(element);
  return element;
}

afterEach(() => {
  while (document.body.firstChild) {
    document.body.removeChild(document.body.firstChild);
  }
});

describe("single-value gauge", () => {
  it("draws an arc proportional to the value", () => {
    const element = build({ value: 85, status: "healthy" });
    const arc = element.shadowRoot.querySelector(".donut__arc");
    const [drawn] = arc.style.strokeDasharray.split(" ").map(parseFloat);

    expect(drawn).toBeCloseTo(CIRCUMFERENCE * 0.85, 1);
  });

  it("renders the percentage and the status sublabel", () => {
    const element = build({ value: 92, valueLabel: "92%", sublabel: "Good" });

    expect(element.shadowRoot.querySelector(".donut__value").textContent).toBe(
      "92%"
    );
    expect(element.shadowRoot.querySelector(".donut__sub").textContent).toBe(
      "Good"
    );
  });

  it("clamps out-of-range values instead of overdrawing the ring", () => {
    const over = build({ value: 140 });
    const [drawn] = over.shadowRoot
      .querySelector(".donut__arc")
      .style.strokeDasharray.split(" ")
      .map(parseFloat);
    expect(drawn).toBeCloseTo(CIRCUMFERENCE, 1);

    const under = build({ value: -20 });
    const [none] = under.shadowRoot
      .querySelector(".donut__arc")
      .style.strokeDasharray.split(" ")
      .map(parseFloat);
    expect(none).toBe(0);
  });

  it("always exposes a text equivalent of the ring", () => {
    const element = build({
      value: 83,
      valueLabel: "83%",
      sublabel: "Healthy"
    });
    expect(element.shadowRoot.querySelector(".acc-sr-only").textContent).toBe(
      "83% Healthy"
    );
  });
});

describe("segmented ring", () => {
  const segments = [
    { id: "h", value: 5, status: "healthy" },
    { id: "w", value: 0, status: "warning" },
    { id: "d", value: 1, status: "critical" }
  ];

  it("draws one arc per segment", () => {
    const element = build({ segments, value: 83 });
    expect(element.shadowRoot.querySelectorAll(".donut__arc")).toHaveLength(3);
  });

  it("separates touching segments with a surface gap rather than a stroke", () => {
    const element = build({
      segments: segments.filter((s) => s.value > 0),
      value: 83
    });
    const arcs = [...element.shadowRoot.querySelectorAll(".donut__arc")];

    const drawn = arcs.map((a) =>
      parseFloat(a.style.strokeDasharray.split(" ")[0])
    );
    const exact = [(5 / 6) * CIRCUMFERENCE, (1 / 6) * CIRCUMFERENCE];

    drawn.forEach((length, index) => {
      expect(length).toBeLessThan(exact[index]);
      expect(length).toBeGreaterThan(exact[index] - 4);
    });

    arcs.forEach((arc) => expect(arc.style.stroke).toBeTruthy());
  });

  it("renders nothing when every segment is zero", () => {
    const element = build({
      segments: [{ id: "a", value: 0, status: "healthy" }]
    });
    expect(element.shadowRoot.querySelectorAll(".donut__arc")).toHaveLength(0);
  });
});
