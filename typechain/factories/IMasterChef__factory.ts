/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { Contract, Signer } from "ethers";
import { Provider } from "@ethersproject/providers";

import type { IKukuFarmer } from "../IKukuFarmer";

export class IKukuFarmer__factory {
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): IKukuFarmer {
    return new Contract(address, _abi, signerOrProvider) as IKukuFarmer;
  }
}

const _abi = [
  {
    inputs: [
      {
        internalType: "uint256",
        name: "_pid",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "_amount",
        type: "uint256",
      },
    ],
    name: "deposit",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "pid",
        type: "uint256",
      },
    ],
    name: "poolInfo",
    outputs: [
      {
        components: [
          {
            internalType: "contract IERC20",
            name: "lpToken",
            type: "address",
          },
          {
            internalType: "uint256",
            name: "allocPoint",
            type: "uint256",
          },
          {
            internalType: "uint256",
            name: "lastRewardBlock",
            type: "uint256",
          },
          {
            internalType: "uint256",
            name: "accKukuPerShare",
            type: "uint256",
          },
        ],
        internalType: "struct IKukuFarmer.PoolInfo",
        name: "",
        type: "tuple",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "totalAllocPoint",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
];
