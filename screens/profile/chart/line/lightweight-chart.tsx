import { createChart, IChartApi, LineData } from "lightweight-charts";
import React, { useEffect, useRef } from "react";

import stocks from "./stocks.json"; // Import the stock data from the JSON file

// Helper to convert Unix timestamp to Date
const formatTimestampToDate = (timestamp: number): string => {
  const date = new Date(timestamp);
  return date.toISOString().split("T")[0]; // Returns 'YYYY-MM-DD'
};

const LighweightChart: React.FC = () => {
  const chartContainerRef = useRef<HTMLDivElement>(null);
  const chartInstanceRef = useRef<IChartApi | null>(null);

  useEffect(() => {
    if (!chartContainerRef.current) return;

    const chart = createChart(chartContainerRef.current, {
      width: chartContainerRef.current.clientWidth,
      height: 300,
      watermark: {
        color: "rgba(0, 0, 0, 0)",
      },
      layout: {
        attributionLogo: false,
      },
    });
    chartInstanceRef.current = chart;

    const lineSeries = chart.addLineSeries({
      color: "#2196F3",
      lineWidth: 2,
    });

    // Prepare the data by formatting timestamps and extracting closing prices
    const data: LineData[] = stocks.results.map(
      (entry: { t: number; c: number }) => ({
        time: formatTimestampToDate(entry.t),
        value: entry.c,
      }),
    );

    // Set the data for the chart
    lineSeries.setData(data);

    // Handle resizing
    const handleResize = () => {
      if (chartContainerRef.current) {
        chart.resize(chartContainerRef.current.clientWidth, 300);
      }
    };
    window.addEventListener("resize", handleResize);

    // Cleanup
    return () => {
      window.removeEventListener("resize", handleResize);
      chart.remove();
    };
  }, []);

  return (
    <div ref={chartContainerRef} style={{ width: "100%", height: "300px" }} />
  );
};

export default LighweightChart;
