defmodule Mix.Tasks.Holidefs.Download do
  use Mix.Task

  alias Holidefs.Definition

  @shortdoc "Downloads the .yaml files with the calendar definitions."

  @moduledoc """
  Downloads the definition files from https://github.com/holidays/definitions.

  ## Examples

      mix holidefs.download

  ## Command line options

    * `-l`, `--locale` - the locale code (or list of locale codes separated
      by comma). All locales by default

    * `-c`, `--clean` - removes all locale files that are not needed anymore
      before processing the list

  """

  @version "master"
  @endpoint "https://raw.githubusercontent.com/holidays/definitions/#{@version}"
  @path Path.join(:code.priv_dir(:holidefs), "/calendars/definitions")

  @switches [locale: :string, clean: :boolean]
  @aliases [l: :locale, c: :clean]

  @renamed_locales %{
    co: :es_co,
    rs: :rs_la,
    be: :be_nl,
    fed: :federal_reserve
  }

  @doc false
  def run(args) do
    {:ok, _apps} = Application.ensure_all_started(:download)
    File.mkdir_p!(@path)

    args
    |> read_opts()
    |> download_all()
  end

  defp download_all(opts) do
    if opts[:clean] do
      for filename <- File.ls!(@path) do
        [code, _] = String.split(filename, ".")

        if code not in codes() do
          path = Path.join(@path, filename)
          File.rm!(path)
          Mix.shell().info([:red, "* deleted ", :reset, path])
        end
      end
    end

    for code <- opts.locale do
      check_locale(code)

      case download(code, Definition.file_path(code, @path)) do
        {:ok, filename} ->
          relative_path = Path.relative_to_cwd(filename)
          Mix.shell().info([:green, "* downloaded ", :reset, relative_path])

        {:error, {:skipped, path}} ->
          Mix.shell().info([:yellow, "* skipped ", :reset, path])

        {:error, :user_aborted} ->
          raise_download(code, "aborted by user")

        {:error, reason} ->
          raise_download(code, reason)
      end
    end
  end

  defp check_locale(code) do
    if code not in codes() do
      raise_download(code, "locale is not allowed")
    end
  end

  defp codes do
    Map.keys(Holidefs.locales())
  end

  defp download(code, path) do
    case Download.from("#{@endpoint}/#{renamed_locale(code)}.yaml", path: path) do
      {:ok, downloaded_path} ->
        if renamed_locale?(code) do
          content =
            downloaded_path
            |> File.stream!()
            |> Enum.map(
              &String.replace(&1, Atom.to_string(renamed_locale(code)), Atom.to_string(code))
            )

          File.write!(downloaded_path, content)
        end

        {:ok, downloaded_path}

      {:error, :eexist} ->
        resolve_conflict(code, path)

      {:error, reason, status} ->
        {:error, "Download failed! Reason: #{inspect(reason)}, status code: #{status}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp renamed_locale?(code), do: code in Map.keys(@renamed_locales)

  defp renamed_locale(code), do: @renamed_locales[code] || code

  defp resolve_conflict(code, path) do
    resolve_conflict(code, path, Process.get(:conflict_action))
  end

  defp resolve_conflict(code, path, nil) do
    message = """
    ## CONFLICT ##

    The file #{inspect(path)} already exist.
    What should we do with this conflict?

    [R]eplace all, [r]eplace, [S]skip all or [s]kip (anything else aborts)
    """

    case message |> Mix.shell().prompt() |> String.trim() do
      "R" ->
        Process.put(:conflict_action, :replace)
        replace(code, path)

      "r" ->
        replace(code, path)

      "S" ->
        Process.put(:conflict_action, :skip)
        {:error, {:skipped, path}}

      "s" ->
        {:error, {:skipped, path}}

      _ ->
        {:error, :user_aborted}
    end
  end

  defp resolve_conflict(code, path, :replace) do
    replace(code, path)
  end

  defp resolve_conflict(_, path, :skip) do
    {:error, {:skipped, path}}
  end

  defp replace(code, path) do
    File.rm!(path)
    Mix.shell().info([:red, "* deleted ", :reset, path])
    download(code, path)
  end

  @spec raise_download(atom, String.t()) :: no_return()
  defp raise_download(code, reason) do
    Mix.raise("""
    Error while downloading definition file for locale #{code}.
    Reason: #{reason}
    """)
  end

  defp default_options do
    %{locale: codes()}
  end

  defp read_opts(args) do
    args
    |> OptionParser.parse(switches: @switches, aliases: @aliases)
    |> handle_opts()
    |> Enum.into(default_options())
  end

  defp handle_opts({opts, _, _}), do: handle_opts(opts, [])

  defp handle_opts([], acc), do: acc

  defp handle_opts([{:locale, locale} | tail], acc),
    do: handle_opts(tail, [{:locale, handle_locale(locale)} | acc])

  defp handle_opts([head | tail], acc), do: handle_opts(tail, [head | acc])

  defp handle_locale(locale) when is_bitstring(locale) do
    locale
    |> String.split(",")
    |> Enum.map(&String.to_atom/1)
  end
end
