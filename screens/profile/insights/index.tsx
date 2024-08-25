import { QuestionMarkIcon } from "@radix-ui/react-icons";

import IconButton from "@/components/icon-button";
import ContentBox from "@/components/content-box";
import LineChart from "./line";

export const Insights = () => {
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
