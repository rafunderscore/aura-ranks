import {
  CalendarIcon,
  DotsHorizontalIcon,
  DrawingPinIcon,
  Link1Icon,
} from "@radix-ui/react-icons";
import Image from "next/image";

import Button from "@/components/button";
import IconButton from "@/components/icon-button";
import Label from "@/components/label";
import styles from "@/screens/profile/header/styles.module.scss";

const MOCK_USER = {
  name: "Jordan Terrell Carter",
  username: "playboicarti",
  bio: "Jordan Terrell Carter, known professionally as Playboi Carti, is an American rapper and record producer from Atlanta, Georgia. An influential figure among his generation, he has contributed to the progression of trap music and its rage subgenre.",
  avatar: "https://i.scdn.co/image/ab6761610000e5eb73d4facbd619ae025b5588c7",
  location: "Atlanta, Georgia",
  website: "https://playboicarti.com",
  joined: "Joined October 2024",
  following: 10,
  followers: 230231,
};

export const Header = () => {
  const formatter = new Intl.NumberFormat("en-US", {
    notation: "compact",
    compactDisplay: "short",
    maximumFractionDigits: 1,
  });

  return (
    <div className={styles.header}>
      <div className={styles.avatar}>
        <Image
          src={MOCK_USER.avatar}
          alt={MOCK_USER.name}
          width={128}
          height={128}
        />
      </div>
      <div className={styles.details}>
        <div className={styles.heading}>
          <h1>{MOCK_USER.name}</h1>
          <h2>@{MOCK_USER.username}</h2>
        </div>
        <p>{MOCK_USER.bio}</p>
        <div className={styles.additional}>
          <p>
            <strong>{MOCK_USER.following}</strong> Following
          </p>
          <p>
            <strong>{formatter.format(MOCK_USER.followers)}</strong> Followers
          </p>
          <Label icon={<CalendarIcon />} text={MOCK_USER.joined} />
          <Label icon={<DrawingPinIcon />} text={MOCK_USER.location} />
          <Label
            icon={<Link1Icon />}
            text={
              <a
                href={MOCK_USER.website}
                target="_blank"
                rel="noopener noreferrer"
              >
                {MOCK_USER.website}
              </a>
            }
          />
        </div>
      </div>
      <div className={styles.actions}>
        <Button>Evaluate</Button>
        <IconButton>
          <DotsHorizontalIcon />
        </IconButton>
      </div>
    </div>
  );
};
