"use client";

import { useParams } from "next/navigation";

const Page = () => {
  const { username } = useParams();

  return (
    <div>
      <h1>Profile for @{username}</h1>
    </div>
  );
};

export default Page;
