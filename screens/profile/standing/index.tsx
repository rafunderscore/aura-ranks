import { QuestionMarkIcon } from "@radix-ui/react-icons";

import ContentBox from "@/components/content-box";
import IconButton from "@/components/icon-button";
import { User } from "@/lib/types/supabase";
import { Stat } from "@/screens/profile/standing/stat";

interface StandingProps extends React.HTMLAttributes<HTMLDivElement> {
  user: User;
}

export const Standing = ({ user }: StandingProps) => {
  const stats = {
    global: {
      key: "global",
      heading: "Current Standing",
      standout: "1st",
      subtext: user.aura_level,
      value: 7.44,
      sign: "positive" as const,
    },
    recent: {
      key: "current",
      heading: "Recent Standing",
      standout: "Ethereal",
      subtext: user.aura_level,
      value: 7.44,
      sign: "positive" as const,
    },
  };

  return (
    <ContentBox
      heading="Profile Standing"
      actions={[
        <IconButton key="question-mark">
          <QuestionMarkIcon />
        </IconButton>,
      ]}
      items={Object.values(stats).map(({ key, ...stat }) => (
        <Stat key={key} {...stat} subtext={String(stat.subtext)} />
      ))}
    />
  );
};
