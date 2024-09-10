import { QuestionMarkIcon } from "@radix-ui/react-icons";

import ContentBox from "@/components/content-box";
import IconButton from "@/components/icon-button";

import LineChart from "./line";

export const Chart = () => {
  return (
    <ContentBox
      heading="Graphical Insights"
      actions={[
        <IconButton key="question-mark">
          <QuestionMarkIcon />
        </IconButton>,
      ]}
      items={[<LineChart key="line-chart" />]}
      layout="graph"
    />
  );
};
