module SuppressLanguageCharset
  refine Mechanize::HTTP::Agent do
    def request_language_charset(request)
      # no-op
    end
  end
end