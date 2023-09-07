import hyper from "@macrostrat/hyper";
import {
  useMapRef,
  useMapDispatch,
  useMapPosition,
} from "@macrostrat/mapbox-react";
import {
  mapViewInfo,
  MapPosition,
  setMapPosition,
} from "@macrostrat/mapbox-utils";
import classNames from "classnames";
import mapboxgl from "mapbox-gl";
import { useEffect, useRef, useCallback } from "react";
import styles from "./main.module.sass";
import rootStyles from "../main.module.sass";
import { enable3DTerrain } from "./terrain";
import {
  MapLoadingReporter,
  MapMovedReporter,
  MapPaddingManager,
  MapResizeManager,
} from "../helpers";
import "mapbox-gl/dist/mapbox-gl.css";
import { getMapPadding } from "../utils";

const h = hyper.styled({ ...styles, ...rootStyles });

type MapboxCoreOptions = Omit<mapboxgl.MapboxOptions, "container">;

export interface MapViewProps extends MapboxCoreOptions {
  showLineSymbols?: boolean;
  children?: React.ReactNode;
  accessToken?: string;
  terrainSourceID?: string;
  enableTerrain?: boolean;
  infoMarkerPosition?: mapboxgl.LngLatLike;
  //style: mapboxgl.Style | string;
  //transformRequest?: mapboxgl.TransformRequestFunction;
  mapPosition?: MapPosition;
  onMapLoad?: (map: mapboxgl.Map) => void;
}

export interface MapboxOptionsExt extends MapboxCoreOptions {
  mapPosition?: MapPosition;
}

function defaultInitializeMap(container, args: MapboxOptionsExt = {}) {
  const { mapPosition, ...rest } = args;

  const map = new mapboxgl.Map({
    container,
    maxZoom: 18,
    //maxTileCacheSize: 0,
    logoPosition: "bottom-left",
    trackResize: true,
    antialias: true,
    optimizeForTerrain: true,
    ...rest,
  });

  // set initial map position
  if (mapPosition != null) {
    setMapPosition(map, mapPosition);
  }

  //setMapPosition(map, mapPosition);
  return map;
}

const defaultMapPosition: MapPosition = {
  camera: {
    lat: 34,
    lng: -120,
    altitude: 300000,
  },
};

export function MapView(props: MapViewProps) {
  let { terrainSourceID } = props;
  const {
    enableTerrain = true,
    style,
    mapPosition = defaultMapPosition,
    initializeMap = defaultInitializeMap,
    children,
    accessToken,
    infoMarkerPosition,
    transformRequest,
    projection,
    onMapLoaded = null,
    onStyleLoaded = null,
    ...rest
  } = props;
  if (enableTerrain) {
    terrainSourceID ??= "mapbox-3d-dem";
  }

  if (accessToken != null) {
    mapboxgl.accessToken = accessToken;
  }

  const dispatch = useMapDispatch();
  let mapRef = useMapRef();
  const ref = useRef<HTMLDivElement>();
  const parentRef = useRef<HTMLDivElement>();

  // Keep track of map position for reloads
  useEffect(() => {
    console.log("Map updated", mapRef.current);
  }, [mapRef.current]);

  useEffect(() => {
    if (style == null) return;
    if (mapRef.current != null) {
      console.log("Setting style", style);
      mapRef.current.setStyle(style);
      return;
    }
    const map = initializeMap(ref.current, {
      style,
      projection,
      mapPosition,
      padding: getMapPadding(ref, parentRef),
      ...rest,
    });
    map.on("style.load", () => {
      onStyleLoaded?.(map);
      dispatch({ type: "set-style-loaded", payload: true });
    });
    onMapLoaded?.(map);
    dispatch({ type: "set-map", payload: map });
  }, [style]);

  // Map style updating
  // useEffect(() => {
  //   if (mapRef?.current == null || style == null) return;
  //   mapRef?.current?.setStyle(style);
  // }, [mapRef.current, style]);

  // Set map position if it changes
  // useEffect(() => {
  //   const map = mapRef.current;
  //   if (map == null || mapPosition == null) return;
  //   setMapPosition(map, mapPosition);
  // }, [mapPosition]);

  const _computedMapPosition = useMapPosition();
  const { mapUse3D, mapIsRotated } = mapViewInfo(_computedMapPosition);

  // Get map projection
  const _projection = mapRef.current?.getProjection()?.name ?? "mercator";

  const className = classNames(
    {
      "is-rotated": mapIsRotated ?? false,
      "is-3d-available": mapUse3D ?? false,
    },
    `${_projection}-projection`
  );

  return h("div.map-view-container.main-view", { ref: parentRef }, [
    h("div.mapbox-map#map", { ref, className }),
    h(MapLoadingReporter, {
      ignoredSources: ["elevationMarker", "crossSectionEndpoints"],
    }),
    h(MapMovedReporter),
    h(MapResizeManager, { containerRef: ref }),
    h(MapPaddingManager, { containerRef: ref, parentRef, infoMarkerPosition }),
    h(MapTerrainManager, { mapUse3D, terrainSourceID }),
    children,
  ]);
}

export function MapTerrainManager({
  mapUse3D,
  terrainSourceID,
}: {
  mapUse3D?: boolean;
  terrainSourceID?: string;
}) {
  const mapRef = useMapRef();

  useEffect(() => {
    const map = mapRef.current;
    if (map == null) return;
    enable3DTerrain(map, mapUse3D, terrainSourceID);
  }, [mapRef.current, mapUse3D]);
  return null;
}
