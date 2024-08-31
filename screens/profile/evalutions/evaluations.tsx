import { QuestionMarkIcon } from "@radix-ui/react-icons";

import ContentBox from "@/components/content-box";
import IconButton from "@/components/icon-button";
import { UserEvaluation } from "@/lib/types/supabase";
import * as Profile from "@/screens/profile";

interface EvaluationsProps extends React.HTMLAttributes<HTMLDivElement> {
  evaluations: UserEvaluation[];
}

export const Evaluations = ({ evaluations }: EvaluationsProps) => {
  return (
    <ContentBox
      layout="evaluations"
      heading={`Evaluations (${evaluations.length})`}
      actions={[
        <IconButton key="question-mark">
          <QuestionMarkIcon />
        </IconButton>,
      ]}
      items={evaluations.map((evaluation) => (
        <Profile.Evaluation
          evaluation={evaluation}
          end={evaluations.indexOf(evaluation) === evaluations.length - 1}
        />
      ))}
    />
  );
};
