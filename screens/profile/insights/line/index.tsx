"use client";

import { ResponsiveLineCanvas } from "@nivo/line";
import { data } from "./data";

const LineChart = () => {
  return (
    <ResponsiveLineCanvas
      data={data}
      margin={{ top: 24 }}
      xScale={{ type: "linear" }}
      yScale={{ type: "linear", stacked: false, min: -2000, max: 2000 }}
      yFormat=" >-.2f"
      axisTop={null}
      axisRight={null}
      axisLeft={null}
      lineWidth={2}
      pointSize={0}
      enableTouchCrosshair={true}
    />
  );
};

export default LineChart;
