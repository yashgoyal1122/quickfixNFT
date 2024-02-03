import React from "react";
import img1 from "../assets/Screenshot 2024-02-03 at 6.41.46 PM.png";
import img2 from "../assets/Screenshot 2024-02-03 at 6.42.01 PM.png";

function Collection() {
  return (
    <div className="flex-1 bg-[#c7c8cc] py-16 flex justify-center items-center">
      <div className="bg-white max-w-fit px-20 py-5 flex flex-col gap-y-4">
        <h1 className="text-[25px]">
          Mint your NFT Collection, here are some NFT's
        </h1>
        <div className="border max-w-fit px-4 flex flex-col gap-y-5">
          <div className="w-full px-40">
            <img src={img1} alt="image-1" className="w-[600px]" />
          </div>
          <h1>What mathematical constant has 13 characters in its name?</h1>

          <p>
            <strong>ID</strong> : 0
          </p>
          <p>
            <strong>SYMBOL</strong> : Math
          </p>
          <p>
            <strong>Description</strong>: Hints: Think of mathematical constants
          </p>
        </div>
      </div>
    </div>
  );
}

export default Collection;
