import React from "react";

const Essence: React.FC<React.SVGProps<SVGSVGElement>> = (props) => {
  return (
    <svg
      width="15"
      height="15"
      viewBox="0 0 15 15"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      {...props}
    >
      <path
        d="M9.42543 14.2436H8.25355L8.25355 0.479403L9.42543 0.479403L9.42543 14.2436ZM7.03374 14.2436H5.86186L5.86186 0.479403L7.03374 0.479403L7.03374 14.2436ZM12.9091 2.00284L4.46094 4.18679V4.288L12.9091 6.51456V8.20845L4.45561 10.435V10.5362L12.9091 12.7202L12.9091 14.3182L2 11.3672V9.6733L10.1712 7.40412V7.31889L2 5.04972L2 3.35582L12.9091 0.40483V2.00284Z"
        fill={props.color || "black"}
      />
    </svg>
  );
};

export { Essence };
