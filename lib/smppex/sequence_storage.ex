defmodule SMPPEX.SequenceStorage do
  @moduledoc """
    The purpose of this behaviour, is to allow custom sequence number storage, to allow for persistent tracking
    of sequence numbers
  """

  @doc """
    initialize the sequence storage

    Returns: `{table_name, storage_key}`

    ## Parameters
    - params: required information to setup sequence store
  """
  @callback init_seq(any) :: {String.t, String.t}

  @doc """
    get stored/initial sequence number from storage

    Returns: `sequence :: number`

    ## Parameters
    - table_name: name of table
    - storage_key: key for value

  """
  @callback get_next_seq(String.t, any) :: integer


  @doc """
    increment storage number in storage.

    ## Comment
    this may seem trivial and in most cases will simply provide a += 1 functionality
    but there are strategies that can be may need to be deployed here.
    1. sequence number rollover. some storages may have a max integer. A roll back to 1 once max integer has been
    reached.
    2. save storage number on incrementation. after a x increments, save next sequence number. Reduce the number
    of updates to a persistent store.

    Returns: `next sequence :: number`

    ## Parameters
    - table_name: name of table
    - storage_key: key for value

  """
  @callback incr_seq(String.t, any, integer) :: integer


  @doc """
    save next sequence number to storage

    ## Comment
    is invoked when process crashes

    Returns: `next sequence :: number`

    ## Parameters
    - table_name: name of table
    - storage_key: key for value
    - next_sequence_number: value

  """
  @callback save_next_seq(String.t, any, integer) :: integer

end