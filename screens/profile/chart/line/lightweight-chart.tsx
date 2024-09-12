import { ResponsiveLine } from "@nivo/line";
import React from "react";

import stocks from "./stocks.json";
import styles from "./styles.module.scss";

interface ChartDotsProps {
  style?: React.CSSProperties;
  className?: string;
}

const ChartDots: React.FC<ChartDotsProps> = ({ style, className }) => {
  return <div className={styles.dots} style={style} />;
};

const height = 300;

const gradProps = {
  gradientUnits: "userSpaceOnUse",
  x1: "0",
  y1: "0",
  x2: "0",
  y2: height,
};

const formatTimestampToDate = (timestamp: number): string => {
  const date = new Date(timestamp);
  return date.toISOString().split("T")[0];
};

const NivoLineChartWithGradient: React.FC = () => {
  const data = [
    {
      id: "Opium Inc.",
      color: "url(#gradientA)", // Referencing the gradient by its ID
      data: stocks.results.map((entry: { t: number; c: number }) => ({
        x: formatTimestampToDate(entry.t),
        y: entry.c,
      })),
    },
  ];

  return (
    <div style={{ height: "300px" }} className={styles.line}>
      <ChartDots />

      <svg className={styles.defs}>
        <defs>
          <linearGradient
            id="gradientA"
            x1="0%"
            y1="0%"
            x2="100%"
            y2="100%"
            gradientUnits="userSpaceOnUse"
          >
            <stop stop-color="#7D66D9" />
            <stop offset="0.5" stop-color="#AB4ABA" />
            <stop offset="1" stop-color="#E93D82" />
          </linearGradient>
        </defs>
      </svg>

      <ResponsiveLine
        data={data}
        xScale={{ type: "point" }}
        yScale={{ type: "linear", min: "auto", max: "auto" }}
        axisTop={null}
        axisRight={null}
        axisBottom={null}
        axisLeft={null}
        enableGridX={false}
        colors={["url(#gradientA)"]}
        enableGridY={false}
        enableCrosshair={true}
        crosshairType="bottom-right"
        useMesh={true}
        pointSize={0}
        pointBorderWidth={2}
        pointBorderColor={{ from: "serieColor" }}
        lineWidth={2}
        enableSlices="x"
        /*
         * Custom Gradient Definition
         */
        defs={[
          {
            id: "gradientA",
            type: "linearGradient",
            colors: [
              { offset: 0, color: "#B3AEF5" },
              { offset: "43%", color: "#D7CBE7" },
              { offset: "65%", color: "#E5C8C8" },
              { offset: "100%", color: "#ECBDAA" },
            ],
            x1: "0%",
            y1: "0%",
            x2: "100%",
            y2: "0%",
          },
        ]}
        fill={[{ match: "*", id: "gradientA" }]}
      />
    </div>
  );
};

export default NivoLineChartWithGradient;
