defmodule PrefixWorker do
  def start do
    spawn(fn -> loop() end)
  end

  defp loop do
    receive do
      {:find_prefix, prefix, words, sender} ->
        check_prefix(prefix, words, sender)
        loop()
    end
  end

  defp check_prefix(prefix, words, sender) do
    unless Enum.empty?(words) do
      if String.starts_with?(hd(words), prefix) do
        check_prefix(prefix, tl(words), sender)
      else
        check_prefix(String.slice(prefix, 0..-2//1), words, sender)
      end
    else
      send(sender, {:prefix_result, prefix})
    end
  end
end

defmodule LongestCommonPrefix do
  def find([]), do: ""
  def find([single_word]), do: single_word

  def find(words) do
    [first | rest] = words
    worker = PrefixWorker.start()

    send(worker, {:find_prefix, first, rest, self()})

    receive do
      {:prefix_result, prefix} -> prefix
    end
  end
end
