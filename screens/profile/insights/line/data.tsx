type DataPoint = {
  x: number;
  y: number;
};

type DataSeries = {
  id: string;
  color: string;
  data: DataPoint[];
};

const generateRandomData = (
  id: string,
  color: string,
  numPoints: number,
  minValue: number,
  maxValue: number,
): DataSeries => {
  const data = Array.from({ length: numPoints }, (_, index) => ({
    x: index,
    y: Math.floor(Math.random() * (maxValue - minValue + 1)) + minValue,
  }));

  return {
    id,
    color,
    data,
  };
};

export const data: DataSeries[] = [
  generateRandomData(
    "japan",
    "hsl(101.06796116504854, 100%, 40.3921568627451%)",
    100,
    -1000,
    1000,
  ),
];
