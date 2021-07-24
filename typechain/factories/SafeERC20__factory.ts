/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { Signer } from "ethers";
import { Provider, TransactionRequest } from "@ethersproject/providers";
import { Contract, ContractFactory, Overrides } from "@ethersproject/contracts";

import type { SafeERC20 } from "../SafeERC20";

export class SafeERC20__factory extends ContractFactory {
  constructor(signer?: Signer) {
    super(_abi, _bytecode, signer);
  }

  deploy(overrides?: Overrides): Promise<SafeERC20> {
    return super.deploy(overrides || {}) as Promise<SafeERC20>;
  }
  getDeployTransaction(overrides?: Overrides): TransactionRequest {
    return super.getDeployTransaction(overrides || {});
  }
  attach(address: string): SafeERC20 {
    return super.attach(address) as SafeERC20;
  }
  connect(signer: Signer): SafeERC20__factory {
    return super.connect(signer) as SafeERC20__factory;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): SafeERC20 {
    return new Contract(address, _abi, signerOrProvider) as SafeERC20;
  }
}

const _abi = [
  {
    inputs: [
      {
        internalType: "contract IERC20",
        name: "token",
        type: "IERC20",
      },
    ],
    name: "safeDecimals",
    outputs: [
      {
        internalType: "uint8",
        name: "",
        type: "uint8",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
];

const _bytecode =
  "0x6101b8610026600b82828239805160001a60731461001957fe5b30600052607381538281f3fe73000000000000000000000000000000000000000030146080604052600436106100355760003560e01c806372a58ae11461003a575b600080fd5b6100606004803603602081101561005057600080fd5b50356001600160a01b0316610076565b6040805160ff9092168252519081900360200190f35b60408051600481526024810182526020810180516001600160e01b031663313ce56760e01b1781529151815160009384936060936001600160a01b03881693919290918291908083835b602083106100df5780518252601f1990920191602091820191016100c0565b6001836020036101000a038019825116818451168082178552505050505050905001915050600060405180830381855afa9150503d806000811461013f576040519150601f19603f3d011682016040523d82523d6000602084013e610144565b606091505b5091509150818015610157575080516020145b61016257601261017a565b80806020019051602081101561017757600080fd5b50515b94935050505056fea26469706673582212203eed241855aee09c940d4f1f40178415e7d2efa73cefed9e16851baac6c3501264736f6c634300060c0033";
