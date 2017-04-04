defmodule SMPPEX.SequenceStorage do
  @moduledoc """
    The purpose of this behaviour, is to allow custom sequence number storage, to allow for persistent tracking
    of sequence numbers
  """
  @callback init_seq(any) :: {String.t, String.t}
  @callback get_next_seq(String.t, any) :: integer
  @callback save_next_seq(String.t, any, integer) :: integer
end