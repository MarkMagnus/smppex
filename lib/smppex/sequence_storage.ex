defmodule SMPPEX.SequenceStorage do
  @moduledoc """
    The purpose of this behaviour, is to allow custom sequence number storage, to allow for persistent tracking
    of sequence numbers
  """
  @callback init_seq() :: {String.t, String.t}
  @callback get_next_seq(String.t, String.t) :: integer
  @callback save_next_seq(String.t, String.t, integer) :: integer
end