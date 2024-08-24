import { DotsHorizontalIcon, QuestionMarkIcon } from "@radix-ui/react-icons";

import Button from "@/components/button";
import IconButton from "@/components/icon-button";
import ContentBox from "@/components/content-box";
import { Stat } from "@/screens/profile/standing/stat";

const MOCK_STATS = {
  global: {
    heading: "Global Standing",
    standout: "1st",
    subtext: "370,071,354",
    value: 7.44,
    sign: "positive" as const,
  },
  current: {
    heading: "Current Standing",
    standout: "Ethereal",
    subtext: "370,071,354",
    value: 7.44,
    sign: "positive" as const,
  },

  recent: {
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
        <IconButton>
          <QuestionMarkIcon />
        </IconButton>,
      ]}
      items={[
        <Stat {...MOCK_STATS.global} />,
        <Stat {...MOCK_STATS.current} />,
        <Stat {...MOCK_STATS.recent} />,
      ]}
    />
  );
};
