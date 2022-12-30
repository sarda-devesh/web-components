import React, { Component, useContext } from "react";
import h from "react-hyperscript";
import classNames from "classnames";
import T from "prop-types";
import {
  SimpleFrame,
  GrainsizeFrame,
  ClipToFrame,
  UUIDComponent,
} from "../frame";
import {
  FaciesContext,
  ColumnContext,
  ColumnLayoutContext,
  ColumnLayoutProvider,
} from "../context";
import { GeologicPattern, PatternType } from "./patterns";

// Malformed es6 module
let v = require("react-svg-textures");
if (v.default != null) {
  v = v.default;
}
const { Lines } = v;

const symbolIndex = {
  "dolomite-limestone": 641,
  lime_mudstone: 627,
  sandstone: 607,
  siltstone: 616,
  "dolomitic siltstone": 616,
  shale: 620,
  limestone: 627,
  dolomite: 642,
  conglomerate: 602,
  "dolomite-mudstone": 642,
  mudstone: 620,
  "sandy-dolomite": 645,
  quartzite: 702,
};

const isCarbonateSymbol = function (d) {
  /*
  Does this FGDC pattern correspond to a carbonate rock?
  */
  if (d < 627) {
    return false;
  }
  if (d > 648) {
    return false;
  }
  return true;
};

const defaultResolveID = function (d) {
  // Changed pattern to lithology
  if (d == null) return null;
  const pat = d.fgdc_pattern ?? symbolIndex[d.pattern] ?? d.pattern;
  if (pat == null) return null;
  return `${pat}`;
};

const carbonateResolveID = function (d) {
  // Just whether a carbonate or not
  v = defaultResolveID(d);
  if (v == null) {
    return v;
  }
  if (isCarbonateSymbol(v)) {
    return 627;
  } else {
    return -1;
  }
};

const __divisionSize = function (d) {
  let { bottom, top } = d;
  if (top < bottom) {
    [top, bottom] = [bottom, top];
  }
  return [bottom, top];
};

class ColumnRect extends Component {
  static initClass() {
    this.contextType = ColumnContext;
    this.propTypes = {
      division: T.object.isRequired,
      padWidth: T.bool,
    };
    this.defaultProps = {
      padWidth: false,
    };
  }
  render() {
    const { scale } = this.context;
    let { division: d, padWidth, key, width, ...rest } = this.props;
    const [bottom, top] = __divisionSize(d);
    const y = scale(top);
    let x = 0;
    if (padWidth) {
      x -= 5;
      width += 10;
    }
    const height = scale(bottom) - y;
    if (key == null) {
      key = d.id;
    }
    return h("rect", { x, y, width, height, key, ...rest });
  }
}
ColumnRect.initClass();

const expandDivisionsByKey = function (divisions, key) {
  const __ = [{ ...divisions[0] }];
  for (let d of Array.from(divisions)) {
    const ix = __.length - 1;
    const shouldSkip = d[key] == null || d[key] === __[ix][key];
    if (shouldSkip) {
      __[ix].top = d.top;
    } else {
      __.push({ ...d });
    }
  }
  return __;
  if (__.length === 1) {
    return null;
  }
};

const ParameterIntervals = function (props) {
  const { divisions, width } = useContext(ColumnLayoutContext);
  const { padWidth, parameter: key, fillForInterval, minimumHeight } = props;
  const newDivisions = expandDivisionsByKey(divisions, key);
  if (newDivisions.length === 1) {
    return null;
  }
  return h(
    "g",
    { className: key },
    newDivisions.map((div) =>
      h(ColumnRect, {
        className: classNames(key, div.id),
        division: div,
        padWidth,
        fill: fillForInterval(div[key], div),
        width,
      })
    )
  );
};

ParameterIntervals.propTypes = {
  padWidth: T.number,
  parameter: T.string.isRequired,
  fillForInterval: T.func.isRequired,
};

const FaciesIntervals = function (props) {
  const { getFaciesColor } = useContext(FaciesContext);
  return h(ParameterIntervals, {
    parameter: "facies",
    fillForInterval(param, division) {
      const { facies, facies_color } = division;
      return getFaciesColor(facies) || facies_color;
    },
    ...props,
  });
};

const FaciesColumnInner = FaciesIntervals;

class CoveredOverlay extends UUIDComponent {
  static contextType = ColumnLayoutContext;
  render() {
    const { divisions, width } = this.context;
    const fill = `url(#${this.UUID}-covered)`;
    const coveredDivs = divisions.filter((d) => d.covered);

    return h("g.covered-overlay", {}, [
      h("defs", [
        h(Lines, {
          id: `${this.UUID}-covered`,
          size: 9,
          strokeWidth: 3,
          stroke: "rgba(0,0,0,0.5)",
        }),
      ]),
      h(
        "g.main",
        coveredDivs.map((d) => {
          return h(ColumnRect, { division: d, width, fill });
        })
      ),
    ]);
  }
}

const LithologySymbolDefs = function (props) {
  let { resolveID, divisions, UUID, scalePattern } = props;
  if (scalePattern == null) {
    scalePattern = () => 1;
  }
  if (divisions == null) {
    ({ divisions } = useContext(ColumnContext));
  }

  const __ = divisions
    .map((d) => resolveID(d))
    .filter((x, i, arr) => arr.indexOf(x) === i);

  return h(
    "defs",
    __.map(function (id, i) {
      if (id === -1) {
        return null;
      }
      let sz = 100;
      if (scalePattern != null) {
        const scalar = scalePattern(id);
        sz *= scalar;
      }
      return h(GeologicPattern, {
        key: i,
        prefix: UUID,
        id,
        width: sz,
        height: sz,
      });
    })
  );
};

class LithologyBoxes extends UUIDComponent {
  constructor(...args) {
    super(...args);
    this.constructLithologyDivisions =
      this.constructLithologyDivisions.bind(this);
    this.renderEach = this.renderEach.bind(this);
  }

  static initClass() {
    this.contextType = ColumnLayoutContext;
    this.defaultProps = {
      resolveID: defaultResolveID,
      minimumHeight: 0,
    };
  }
  constructLithologyDivisions() {
    let d, patternID;
    const { divisions } = this.context;
    const { resolveID, minimumHeight } = this.props;
    const __ = [];
    for (d of Array.from(divisions)) {
      const ix = __.length - 1;
      patternID = resolveID(d);
      if (ix === -1) {
        __.push({ ...d, patternID });
        continue;
      }
      const sameAsLast = patternID === resolveID(__[ix]);
      const shouldSkip = patternID == null || sameAsLast;
      if (shouldSkip) {
        __[ix].top = d.top;
      } else {
        __.push({ ...d, patternID });
      }
    }

    // Allow removing of items by minimum height
    if (minimumHeight > 0) {
      const nextVals = [];
      for (let i = 0; i < __.length; i++) {
        d = __[i];
        const heightTooSmall = d.top - d.bottom < minimumHeight;
        if (heightTooSmall && __[i + 1] != null) {
          var name;
          __[i + 1].bottom = d.bottom;
          if (__[(name = i + 1)].patternID == null) {
            __[name].patternID = resolveID(d);
          }
        } else {
          nextVals.push(d);
        }
      }
      return nextVals;
    }
    return __;
  }

  renderEach(d) {
    const { width } = this.context;
    const className = classNames(
      {
        definite: d.definite_boundary,
        covered: d.covered,
      },
      "lithology"
    );
    let fill = `url(#${this.UUID}-${d.patternID})`;
    if (d.patternID === -1) {
      fill = "transparent";
    }
    return h(ColumnRect, { width, division: d, className, fill });
  }

  render() {
    const divisions = this.constructLithologyDivisions();
    const { resolveID } = this.props;
    return h("g.lithology", [
      h(LithologySymbolDefs, {
        divisions,
        resolveID,
        UUID: this.UUID,
      }),
      h("g", divisions.map(this.renderEach)),
    ]);
  }
}
LithologyBoxes.initClass();

const LithologyColumnInner = LithologyBoxes;

interface LithologyColumnProps {
  width: number;
  left?: number;
  children?: React.ReactNode;
}

function LithologyColumn(props: LithologyColumnProps) {
  const { left = 0, shiftY = 0.5, width, children } = props;

  const transform = left != null ? `translate(${left} ${shiftY})` : null;

  return h(ColumnLayoutProvider, { width }, [
    h(
      ClipToFrame,
      {
        className: "lithology-column",
        left,
        shiftY,
        frame: SimpleFrame,
      },
      children
    ),
  ]);
}

const simplifiedResolveID = function (d) {
  const p = symbolIndex[d.fill_pattern];
  if (p != null) {
    return p;
  }
  const fp = d.fill_pattern;
  // Special case for shales since we probably want to emphasize lithology
  if (parseInt(fp) === 624) {
    return defaultResolveID(d);
  } else {
    return fp;
  }
};

const SimplifiedLithologyColumn = (props) =>
  h(LithologyColumnInner, {
    resolveID: simplifiedResolveID,
    ...props,
  });

const GeneralizedSectionColumn = function (props) {
  let { children, frame, ...rest } = props;
  if (frame == null) {
    frame = GrainsizeFrame;
  }
  return h(
    ClipToFrame,
    {
      className: "lithology-column",
      frame,
      ...rest,
    },
    children
  );
};

const CarbonateDivisions = (props) =>
  h(LithologyColumnInner, {
    resolveID: carbonateResolveID,
    ...props,
  });

export * from "./patterns";
export * from "./column-patterns";
export {
  ParameterIntervals,
  LithologyColumn,
  LithologyBoxes,
  GeneralizedSectionColumn,
  defaultResolveID,
  FaciesColumnInner,
  LithologySymbolDefs,
  LithologyColumnInner,
  CarbonateDivisions,
  SimplifiedLithologyColumn,
  CoveredOverlay,
  SimpleFrame,
  GrainsizeFrame,
  ColumnRect,
  expandDivisionsByKey,
  symbolIndex,
  FaciesIntervals,
};
