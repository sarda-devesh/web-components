import h from "@macrostrat/hyper";
import {
  formatCoordForZoomLevel,
  metersToFeet,
  normalizeLng,
} from "@macrostrat/mapbox-utils";
import { formatValue } from "./utils";

export * from "./hash-string";

export function ValueWithUnit(props) {
  const { value, unit } = props;
  return h("span.value-with-unit", [
    h("span.value", [value]),
    h("span.spacer", [" "]),
    h("span.unit", [unit]),
  ]);
}

export function DegreeCoord(props) {
  const { value, labels, precision = 3, format = formatValue } = props;
  const direction = value < 0 ? labels[1] : labels[0];

  return h(ValueWithUnit, {
    value: format(Math.abs(value), precision) + "°",
    unit: direction,
  });
}

export interface LngLatProps {
  /** Map position */
  position: [number, number] | { lat: number; lng: number };
  className?: string;
  /** Zoom level (used to infer coordinate rounding if provided) */
  zoom?: number | null;
  /** Number of decimal places to round coordinates to */
  precision: number | null;
  /** Function to format coordinates */
  format?: (val: number, precision: number) => string;
}

export function LngLatCoords(props: LngLatProps) {
  /** Formatted geographic coordinates */
  const { position, className, precision, zoom } = props;
  let { format } = props;
  if (position == null) {
    return null;
  }
  let lat, lng;
  if (Array.isArray(position)) {
    [lng, lat] = position;
  } else {
    ({ lat, lng } = position);
  }

  if (zoom != null && format == null && precision == null) {
    format = (val, _) => formatCoordForZoomLevel(val, zoom);
  }

  return h("div.lnglat-container", { className }, [
    h("span.lnglat", [
      h(DegreeCoord, {
        value: lat,
        labels: ["N", "S"],
        precision,
        format,
      }),
      ", ",
      h(DegreeCoord, {
        value: normalizeLng(lng),
        labels: ["E", "W"],
        precision,
        format,
      }),
    ]),
  ]);
}

export function Elevation(props) {
  /** Renders an elevation value in meters and a parenthetical conversion to feet. */
  const { elevation, className, includeFeet = true } = props;
  if (elevation == null) return null;
  return h("div.elevation", { className }, [
    h(ValueWithUnit, { value: elevation, unit: "m" }),
    h.if(includeFeet)("span.secondary", [
      " (",
      h(ValueWithUnit, { value: metersToFeet(elevation), unit: "ft" }),
      ")",
    ]),
  ]);
}
