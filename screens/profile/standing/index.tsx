import { QuestionMarkIcon } from "@radix-ui/react-icons";

import IconButton from "@/components/icon-button";
import ContentBox from "@/components/content-box";
import { Stat } from "@/screens/profile/standing/stat";

const MOCK_STATS = {
  global: {
    key: "global",
    heading: "Global Standing",
    standout: "1st",
    subtext: "370,071,354",
    value: 7.44,
    sign: "positive" as const,
  },
  current: {
    key: "current",
    heading: "Current Standing",
    standout: "Ethereal",
    subtext: "370,071,354",
    value: 7.44,
    sign: "positive" as const,
  },
  recent: {
    key: "recent",
    heading: "Recent Standing",
    standout: "Neutral",
    subtext: "71,354",
    value: 32.44,
    sign: "negative" as const,
  },
};

export const Standing = () => {
  return (
    <ContentBox
      heading="Profile Standing"
      actions={[
        <IconButton key="question-mark">
          <QuestionMarkIcon />
        </IconButton>,
      ]}
      items={Object.values(MOCK_STATS).map(({ key, ...stat }) => (
        <Stat key={key} {...stat} />
      ))}
    />
  );
};
