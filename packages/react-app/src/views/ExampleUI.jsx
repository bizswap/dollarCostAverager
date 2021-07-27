/* eslint-disable jsx-a11y/accessible-emoji */

import { SyncOutlined } from "@ant-design/icons";
import { utils } from "ethers";
import { Row, Col, Form, Button, Card, DatePicker, Divider, Input, List, Progress, Slider, Spin, Switch } from "antd";
import React, { useState } from "react";
import { Address, Balance } from "../components";
import { useContractReader } from "eth-hooks";

export default function ExampleUI({
  purpose,
  setPurposeEvents,
  address,
  mainnetProvider,
  localProvider,
  yourLocalBalance,
  price,
  tx,
  readContracts,
  writeContracts,
  mainnetContracts,
  writeExternalContracts,
}) {

  const [deposit, setDeposit] = useState("...");
  const [frequency, setFrequency] = useState("...");
  const [amountPerTx, setAmountPerTx] = useState("...");


  async function openChannel() {
    await tx(writeExternalContracts.DAI.approve("0x1AD9F6c276bbd58CbCfFec4Aa6875E041374AbD3", deposit));
    await tx(writeContracts.YourContract.openChannel(deposit, frequency, amountPerTx));
  }

  return (
    <div>
      <Row justify="center">
        <Col span={8}>
          <Card title="Dollar Cost Averaging Tool">
            <h3>{deposit}</h3>
            <Form
            title="Sample UI"
            onFinish={openChannel}
            >
              <Row justify="center">
                <Col span={8}>
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
                </Col>
              </Row>
            </Form>
          </Card>
        </Col>
      </Row>
    </div>
  );
}
