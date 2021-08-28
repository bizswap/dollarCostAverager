/* eslint-disable jsx-a11y/accessible-emoji */

import { SyncOutlined } from "@ant-design/icons";
import { utils } from "ethers";
import { Row, Col, Form, Button, Card, DatePicker, Divider, Input, List, Progress, Slider, Spin, Switch } from "antd";
import React, { useState } from "react";
import { Address, Balance } from "../components";
import { useContractReader } from "eth-hooks";
import { isRequiredArgument } from "graphql";

export default function ExampleUI({
  address,
  tx,
  readContracts,
  writeContracts,
  writeExternalContracts,
  useContractReader,
  usePoller,
}) {

  const [deposit, setDeposit] = useState("...");
  const [frequency, setFrequency] = useState("...");
  const [amountPerTx, setAmountPerTx] = useState("...");

  const checkIfReady = useContractReader(readContracts, "DCA", "isReady", [address], 3000);
  async function ifReadySwap() {
    if(checkIfReady) {
      await tx(writeContracts.DCA.swapExactInputSingle(address));
    } else {
      console.log("Not ready yet")
    }
  }
  usePoller(() => {
    ifReadySwap();
  }, 120000);

  async function openChannel() {
    await tx(writeExternalContracts.DAI.approve("0x2368f44ae6583163635fdaE39a2aD28ac072997a", deposit));
    await tx(writeContracts.DCA.openChannel(deposit, frequency, amountPerTx));
  }

  return (
    <div>
      <Row justify="center">
        <Col span={8}>
          <Card title="Dollar Cost Averaging Tool">
              <Form
              title="Sample UI"
              onFinish={openChannel}
              >
                <Row justify="center">
                  <Col span={10} offset={1}>
                    <Card title="Open Channel!">
                      <Form.Item
                      label="Deposit Amount">
                        <Input onChange={(e) => {
                          setDeposit(e.target.value);
                        }} />
                      </Form.Item>

                      <Form.Item
                      label="Frequency">
                        <Input onChange={(e) => {
                          setFrequency(e.target.value);
                        }} />
                      </Form.Item>

                      <Form.Item
                      label="Amount Per Tx">
                        <Input onChange={(e) => {
                          setAmountPerTx(e.target.value);
                        }} />
                      </Form.Item>
                      
                      <Form.Item>
                        <Button type="primary" htmlType="submit">Submit!</Button>
                      </Form.Item>
                    </Card>
                  </Col>
                  <Col span={10} offset={1}>
                    <Card title="Your Current Channel">
                      <h3>Balance: PLACEHOLDER</h3>
                      <h3>Frequency: PLACEHOLDER</h3>
                      <h3>AmountPerSwap: PLACEHOLDER</h3>
                      <h3>LastSwap: PLACEHOLDER</h3>
                    </Card>
                  </Col>
                </Row>
              </Form>
          </Card>
        </Col>
      </Row>
    </div>
  );
}
