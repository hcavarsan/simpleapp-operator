defmodule HenriqueOperator.Controller.V1.SimpleAppTest do
  use ExUnit.Case, async: false
  alias HenriqueOperator.Controller.V1.SimpleApp

  describe "add/1" do
    test "returns :ok" do
      event = %{}
      result = SimpleApp.add(event)
      assert result == :ok
    end
  end

  describe "modify/1" do
    test "returns :ok" do
      event = %{}
      result = SimpleApp.modify(event)
      assert result == :ok
    end
  end

  describe "delete/1" do
    test "returns :ok" do
      event = %{}
      result = SimpleApp.delete(event)
      assert result == :ok
    end
  end
end
