defmodule SMPPEX.Protocol.Unpack.Helpers do
  @moduledoc false

  @spec hex?(binary) :: boolean

  def hex?(<< char, rest :: binary >>) when (char >= 48) and (char <= 57), do: hex?(rest)
  def hex?(<< char, rest :: binary >>) when (char >= 65) and (char <= 70), do: hex?(rest)
  def hex?(<< char, rest :: binary >>) when (char >= 97) and (char <= 102), do: hex?(rest)
  def hex?(<<>>), do: true
  def hex?(_), do: false

  @spec dec?(binary) :: boolean

  def dec?(<< char, rest :: binary >>) when (char >= 48) and (char <= 57), do: dec?(rest)
  def dec?(<<>>), do: true
  def dec?(_), do: false

  @spec take_until(binary, integer, integer) :: :not_found | {binary, binary}

  def take_until(bin, char, take_max) do
    _take_until(bin, char, take_max, 0)
  end

  @spec _take_until(binary, integer, integer, integer) :: :not_found | {binary, binary}

  defp _take_until(_bin, _char, take_max, current) when current >= take_max, do: :not_found
  defp _take_until(bin, _char, _take_max, current) when byte_size(bin) <= current, do: :not_found

  defp _take_until(bin, char, take_max, current) do
    case bin do
      << prefix :: binary-size(current), ^char, rest :: binary >> -> {prefix, rest}
      _ -> _take_until(bin, char, take_max, current + 1)
    end
  end

  @spec take_bits(bitstring, integer) :: :error | {:ok, bitstring}
  def take_bits(bitstr, take_max) when is_bitstring(bitstr) and is_integer(take_max), do: _take_bits(bitstr, take_max)
  defp _take_bits(bitstr, take_max) when bit_size(bitstr) <= take_max, do: {:ok, bitstr}
  defp _take_bits(_bitstr, _take_max), do: :error


end

