import { ComponentStory, ComponentMeta } from "@storybook/react";
import { useArgs } from "@storybook/client-api";
import h from "@macrostrat/hyper";

import { SimpleToggle } from "./toggle";

export default {
  title: "Controls/SimpleToggle",
  component: SimpleToggle,
  args: {
    name: "value",
    isOn: true,
    /** A function to toggle the value */
    toggle: () => {},
  },
} as ComponentMeta<typeof SimpleToggle>;

const Template: ComponentStory<typeof SimpleToggle> = (args) => {
  const [{ isOn, ...rest }, updateArgs] = useArgs();
  const toggle = () => updateArgs({ isOn: !isOn, ...rest });
  return h(SimpleToggle, { ...rest, isOn, toggle });
};

export const TestToggle = Template.bind({});
TestToggle.args = { name: "layer" };
