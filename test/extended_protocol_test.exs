defmodule SMPPEX.MCGSM7 do
  use ExUnit.Case

  alias SMPPEX.Pdu.Factory
  alias SMPPEX.Protocol.MandatoryFieldsSpecs
  alias SMPPEX.Protocol

  test "handle default formatting" do
    pdu2 = Factory.submit_sm({"from", 1, 2}, {"to", 1, 2}, "message", 1, 0)
    {:ok, mandatory_fields} = Protocol.build_mandatory_fields(pdu2, MandatoryFieldsSpecs.spec_for(:submit_sm))
    hex_value = mandatory_fields |> Enum.join() |> Hexate.encode()
    assert hex_value == "00010266726f6d000102746f00000000000001000000076d657373616765"
  end

  test "handle ucs formatting" do
    message = <<"m" :: utf16, "e" :: utf16, "s" :: utf16, "s" :: utf16, "a" :: utf16, "g" :: utf16, "e" :: utf16>>
    pdu2 = Factory.submit_sm({"from", 1, 2}, {"to", 1, 2}, message, 1, 8)
    {:ok, mandatory_fields} = Protocol.build_mandatory_fields(pdu2, MandatoryFieldsSpecs.spec_for(:submit_sm))
    hex_value = mandatory_fields |> Enum.join() |> Hexate.encode()
    assert hex_value == "00010266726f6d000102746f000000000000010008000e006d006500730073006100670065"

  end

end