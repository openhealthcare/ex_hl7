defmodule HL7 do
  @type message        :: HL7.Message.t
  @type segment        :: HL7.Segment.t
  @type segment_id     :: HL7.Type.segment_id
  @type sequence       :: HL7.Type.sequence
  @type field          :: HL7.Type.field
  @type item_type      :: HL7.Type.item_type
  @type value_type     :: HL7.Type.value_type
  @type value          :: HL7.Type.value
  @type repetition     :: HL7.Type.repetition
  @type read_option    :: HL7.Reader.option
  @type write_option   :: HL7.Writer.option
  @type read_ret       :: {:ok, HL7.Message.t} |
                          {:incomplete, {(binary -> read_ret), rest :: binary}} |
                          {:error, reason :: any}

  @doc """
  Reads a binary containing an HL7 message converting it to a list of segments.

  ## Arguments

  * `buffer`: a binary containing the HL7 message to be parsed (partial
    messages are allowed).

  * `options`: keyword list with the read options; these are:
    * `input_format`: the format the message in the `buffer` is in; it can be
      either `:wire` for the normal HL7 wire format with carriage-returns as
      segment terminators or `:text` for a format that replaces segment
      terminators with line feeds to easily output messages to a console or
      text file.
    * `trim`: boolean that when set to `true` causes the fields to be
      shortened to their optimal layout, removing trailing empty items (see
      `HL7.Codec` for an explanation of this).

  ## Return values

  * `{:ok, HL7.message}` if the buffer could be parsed successfully, then
    a message will be returned. This is actually a list of `HL7.segment`
    structs (check the [segment.ex](lib/ex_hl7/segment.ex) file to see the
    list of included segment definitions).

  * `{:incomplete, {(binary -> read_ret), rest :: binary}}` if the message
    in the string is not a complete HL7 message, then a function will be
    returned together with the part of the message that could not be parsed.
    You should acquire the remaining part of the message and concatenate it
    to the `rest` of the previous buffer. Finally, you have to call the
    function that was returned passing it the concatenated string.

  * `{:error, reason :: any}` if the contents of the buffer were malformed
    and could not be parsed correctly.

  ## Examples

  Given an HL7 message like the following bound to the `buffer` variable:

      "MSH|^~\\&|CLIENTHL7|CLI01020304|SERVHL7|PREPAGA^112233^IIN|20120201101155||ZQA^Z02^ZQA_Z02|00XX20120201101155|P|2.4|||ER|SU|ARG\\r" <>
      "PRD|PS~4600^^HL70454||^^^B||||30123456789^CU\\r" <>
      "PID|0||1234567890ABC^^^&112233&IIN^HC||unknown\\r" <>
      "PR1|1||903401^^99DH\\r" <>
      "AUT||112233||||||1|0\\r" <>
      "PR1|2||904620^^99DH\\r" <>
      "AUT||112233||||||1|0\\r"

  You could read the message in the following way:

      iex> {:ok, message} = HL7.read(buffer, input_format: :wire, trim: true)

  """
  @spec read(buffer :: binary, [HL7.read_option]) :: HL7.read_ret
  def read(buffer, options \\ []), do:
    HL7.Message.read(HL7.Reader.new(options), buffer)

  @doc """
  Writes a list of HL7 segments into an iolist.

  ## Arguments

  * `message`: a list of HL7 segments to be written into the string.

  * `options`: keyword list with the write options; these are:
    * `output_format`: the format the message will be written in; it can be
      either `:wire` for the normal HL7 wire format with carriage-returns as
      segment terminators or `:text` for a format that replaces segment
      terminators with line feeds to easily output messages to a console or
      text file. Defaults to `:wire`.
    * `separators`: a binary containing the item separators to be used when
      generating the message as returned by `HL7.Codec.compile_separators/1`.
      Defaults to `HL7.Codec.separators`.
    * `trim`: boolean that when set to `true` causes the fields to be
      shortened to their optimal layout, removing trailing empty items (see
      `HL7.Codec` for an explanation of this). Defaults to `true`.

  ## Return value

  iolist containing the message in the selected output format.

  ## Examples

  Given the `message` parsed in the `HL7.read/2` example you could do:

      iex> buffer = HL7.write(message, output_format: :text, trim: true)
      iex> IO.puts(buffer)

      MSH|^~\\&|CLIENTHL7|CLI01020304|SERVHL7|PREPAGA^112233^IIN|20120201101155||ZQA^Z02^ZQA_Z02|00XX20120201101155|P|2.4|||ER|SU|ARG
      PRD|PS~4600^^HL70454||^^^B||||30123456789^CU
      PID|0||1234567890ABC^^^&112233&IIN^HC||unknown
      PR1|1||903401^^99DH
      AUT||112233||||||1|0
      PR1|2||904620^^99DH
      AUT||112233||||||1|0

  """
  @spec write(message, [HL7.write_option]) :: iodata
  def write(message, options \\ []), do:
    HL7.Message.write(HL7.Writer.new(options), message)

  @doc """
  Retrieve the segment ID from a segment.

  ## Return value

  If the argument is an `HL7.segment` the function returns a binary with the
  segment ID; otherwise it returns `nil`.

  ## Examples

      iex> aut = HL7.segment(message, "AUT")
      iex> HL7.segment_id(aut)

      "AUT"

  """
  @spec segment_id(segment) :: segment_id
  defdelegate segment_id(segment), to: HL7.Segment, as: :id

  @doc """
  Retrieve the segment at the given index (0-based)

  ## Return value

  Returns the segment at the given `index` (0-based) or `nil` if the segment
  is not present or the index is out of bounds.
  """
  @spec at(message, index :: integer) :: segment | nil
  defdelegate at(message, index), to: HL7.Message

  @doc """
  Retrieve the segment at the given index (0-based)

  ## Return value

  Returns the segment at the given `index` (0-based) or `default` if the segment
  is not present or the index is out of bounds.
  """
  @spec at(message, index :: integer, segment | nil) :: segment | nil
  defdelegate at(message, index, default), to: HL7.Message

  @doc """
  Return the first repetition of a segment within a message.

  ## Return value

  If a segment with the passed `segment_id` can be found in the `message`
  then the function returns the segment; otherwise it returns `nil`.

  ## Examples

      iex> pr1 = HL7.segment(message, "PR1")
      iex> 1 = pr1.set_id

  """
  @spec segment(message, segment_id) :: segment | nil
  defdelegate segment(message, segment_id), to: HL7.Message

  @doc """
  Return the nth repetition (0-based) of a segment within a message.

  ## Return value

  If the corresponding `repetition` of a segment with the passed `segment_id`
  is present in the `message` then the function returns the segment; otherwise
  it returns `nil`.

  ## Examples

      iex> pr1 = HL7.segment(message, "PR1", 0)
      iex> 1 = pr1.set_id
      iex> pr1 = HL7.segment(message, "PR1", 1)
      iex> 2 = pr1.set_id

  """
  @spec segment(message, segment_id, repetition) :: segment | nil
  defdelegate segment(message, segment_id, repetition), to: HL7.Message

  @doc """
  Return the first grouping of segments with the specified segment IDs.

  In HL7 messages sometimes some segments are immediately followed by other
  segments within the message. This function was created to help find those
  "grouped segments".

  For example, the `PR1` segment is sometimes followed by some other segments
  (e.g. `OBX`, `AUT`, etc.) to include observations and other related
  information for a practice. Note that there might be multiple segment
  groupings in a message.

  ## Return value

  A list of segments corresponding to the segment IDs that were passed. The
  list might not include all of the requested segments if they were not
  present in the message. The function will stop as soon as it finds a segment
  that does not belong to the passed sequence.

  ## Examples

      iex> [pr1, aut] = HL7.paired_segments(message, ["PR1", "AUT"])

  """
  @spec paired_segments(message, [segment_id]) :: [segment]
  defdelegate paired_segments(message, segment_ids), to: HL7.Message

  @doc """
  Return the nth (0-based) grouping of segments with the specified segment IDs.

  In HL7 messages sometimes some segments are immediately followed by other
  segments within the message. This function was created to help find those
  "grouped segments".

  For example, the `PR1` segment is sometimes followed by some other segments
  (e.g. `OBX`, `AUT`, etc.) to include observations and other related
  information for a practice. Note that there might be multiple segment
  groupings in a message.

  ## Return value

  A list of segments corresponding to the segment IDs that were passed. The
  list might not include all of the requested segments if they were not
  present in the message. The function will stop as soon as it finds a segment
  that does not belong to the passed sequence.

  ## Examples

      iex> [pr1, aut] = HL7.paired_segments(message, ["PR1", "AUT"], 0)
      iex> [pr1, aut] = HL7.paired_segments(message, ["PR1", "AUT"], 1)
      iex> [] = HL7.paired_segments(message, ["PR1", "AUT"], 1)
      iex> [aut] = HL7.paired_segments(message, ["AUT", "PR1"], 1)

  """
  @spec paired_segments(message, [segment_id], repetition) :: [segment]
  defdelegate paired_segments(message, segment_ids, repetition), to: HL7.Message

  @doc """
  Return the number of segments with a specified segment ID in an HL7 message.

  ## Examples

      iex> 2 = HL7.segment_count(message, "PR1")
      iex> 0 = HL7.segment_count(message, "OBX")

  """
  @spec segment_count(message, segment_id) :: non_neg_integer
  defdelegate segment_count(message, segment_id), to: HL7.Message

  @spec delete(message, segment_id) :: message
  defdelegate delete(message, segment_id), to: HL7.Message

  @spec delete(message, segment_id, repetition) :: message
  defdelegate delete(message, segment_id, repetition), to: HL7.Message

  @spec insert_before(message, segment_id, segment | [segment]) :: message
  defdelegate insert_before(message, segment_id, segment), to: HL7.Message

  @spec insert_before(message, segment_id, repetition, segment | [segment]) :: message
  defdelegate insert_before(message, segment_id, repetition, segment), to: HL7.Message

  @spec insert_after(message, segment_id, segment | [segment]) :: message
  defdelegate insert_after(message, segment_id, segment), to: HL7.Message

  @spec insert_after(message, segment_id, repetition, segment | [segment]) :: message
  defdelegate insert_after(message, segment_id, repetition, segment), to: HL7.Message

  @spec replace(message, segment_id, segment) :: message
  defdelegate replace(message, segment_id, segment), to: HL7.Message

  @spec replace(message, segment_id, repetition, segment) :: message
  defdelegate replace(message, segment_id, repetition, segment), to: HL7.Message

  @doc """
  Escape a string that may contain separators using the HL7 escaping rules.

  ## Arguments

  * `value`: a string to escape; it may or may not contain separator
    characters.

  * `options`: keyword list with the escape options; these are:
    * `separators`: a binary containing the item separators to be used when
      generating the message as returned by `HL7.Codec.compile_separators/1`.
      Defaults to `HL7.Codec.separators`.
    * `escape_char`: character to be used as escape delimiter. Defaults to `?\\\\`.

  ## Examples

      iex> "ABCDEF" = HL7.escape("ABCDEF")
      iex> "ABC\\\\|\\\\DEF\\\\|\\\\GHI" = HL7.escape("ABC|DEF|GHI", separators: HL7.Codec.separators(), escape_char: ?\\\\)

  """
  @spec escape(binary, options :: Keyword.t) :: binary
  def escape(value, options \\ []) do
    separators = Keyword.get(options, :separators, HL7.Codec.separators())
    escape_char = Keyword.get(options, :escape_char, ?\\)
    HL7.Codec.escape(value, separators, escape_char)
  end

  @doc """
  Convert an escaped string into its original value.

  ## Arguments

  * `value`: a string to unescape; it may or may not contain escaped characters.

  * `options`: keyword list with the unescape options; these are:
    * `escape_char`: character that was used as escape delimiter. Defaults to `?\\\\`.

  ## Examples

      iex> "ABCDEF" = HL7.unescape("ABCDEF")
      iex> "ABC|DEF|GHI" = HL7.unescape("ABC\\\\|\\\\DEF\\\\|\\\\GHI", escape_char: ?\\\\)

  """
  @spec unescape(binary, options :: Keyword.t) :: binary
  def unescape(value, options \\ []) do
    escape_char = Keyword.get(options, :escape_char, ?\\)
    HL7.Codec.unescape(value, escape_char)
  end

end
