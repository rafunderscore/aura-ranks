import { faker } from "@faker-js/faker";

import ContentBox from "@/components/content-box";
import * as Profile from "@/screens/profile";

import { EvaluationType } from "./evaluation";

export const Evaluations = () => {
  const evaluations: EvaluationType[] = Array.from({ length: 10 }, () => ({
    id: faker.string.uuid(),
    name: faker.internet.userName(),
    avatar: `https://api.dicebear.com/9.x/glass/svg?seed=${encodeURIComponent(faker.string.uuid())}`,
    comment: faker.lorem.paragraphs({ min: 2, max: 3 }, "\n\n"),
    essence_used: faker.number.int({ min: 0, max: 1000000 }),
    type: Math.random() > 0.5 ? "positive" : "negative",
    created_at: faker.date.recent(),
    likes: faker.number.int({ max: 100000 }),
    dislikes: faker.number.int({ max: 10000 }),
    shares: faker.number.int({ max: 10000 }),
    responses: faker.number.int({ max: 10000 }),
  }));

  return (
    <ContentBox
      layout="evaluations"
      heading={`Evaluations (${evaluations.length})`}
      items={evaluations.map((evaluation) => (
        <Profile.Evaluation key={evaluation.id} evaluation={evaluation} />
      ))}
    />
  );
};
