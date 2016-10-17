module Kramdown
  module Converter
    class LatexRepositext
      class SmallcapsKerningMap
        module KerningSampleLatexMixin

          extend ActiveSupport::Concern

          module ClassMethods

            # Returns latex for generating the kerning sample document
            def kerning_sample_latex
              kerning_map = new.kerning_map
              kerning_values_map = kerning_map['kerning_values']
              font_names = kerning_values_map.keys
              character_mappings = kerning_map['character_mappings']

              latex = render_latex_prefix(font_names)
              latex << render_latex_body(kerning_values_map, character_mappings)
              latex << render_latex_suffix
              latex
            end

            # @param font_names [Array<String>]
            def render_latex_prefix(font_names)
              font_family_section = font_names.map { |font_name|
                %(\\newfontfamily\\#{ key_for_font_name(font_name) }[Ligatures={NoRequired,NoCommon,NoContextual}]{#{ font_name }})
              }.join("\n")

              %(\\documentclass[10pt]{article}

% nag to be alerted of syntax issues
\\usepackage{nag}

% to get \textscale
\\usepackage{relsize}

% for if-then control flow (RtSmCapsEmulation)
\\usepackage{ifthen}

% fontspec to use custom fonts
\\usepackage{fontspec}
% turn off ligatures
% declare fonts to be used
#{ font_family_section }

% make sure there is no page break in id paragraphs at the end
\\usepackage{needspace}

% package and command dependency boundary

% command to emulate lower-case small-caps chars
% first argument is the text to render in smallcaps
% second argument is an optional kerning adjustment via \\hspace{-0.1em}
\\newcommand{\\RtSmCapsEmulation}[2]
  {%
    \\ifthenelse{\\equal{#2}{none}}%
    {}%
    {\\hspace{#2}}%
    \\textscale{0.7}{#1}%
  }

% environment to render a kerning sample. Pass font key as first argument.
\\newenvironment{KerningSample}[1]
  {%
    #1\\fontsize{22pt}{26.4pt}\\selectfont
  }
  {}

\\begin{document}
This document renders kerning samples for all font, font-attribute, and
character-pair combinations.

To re-generate this document use rt command `export pdf\\_kerning\\_samples`.

The file will be exported to the current language repo's root directory,
named `kerning\\_samples.pdf`.

This document was rendered at #{ Time.now.to_s }.

\\newpage
)
            end

            # @param kerning_values_map [Hash]
            # @param character_mappings [Hash]
            def render_latex_body(kerning_values_map, character_mappings)
              kerning_values_map.map { |font_name, font_name_map|
                render_font_name_section(font_name, font_name_map)
              }.join
            end

            def render_latex_suffix
              %(\n\\end{document})
            end

            # @param font_name [String]
            # @param font_name_map [Hash]
            def render_font_name_section(font_name, font_name_map)
              r = [
                "\\begin{KerningSample}{\\#{ key_for_font_name(font_name) }}",
                font_name,
                "\\end{KerningSample}\n",
                "\\vspace{2em}\n\n",
              ].join("\n")
              r << font_name_map.map { |font_attrs, font_attrs_map|
                render_font_attrs_section(font_name, font_attrs, font_attrs_map)
              }.join
              r << "\\newpage\n\n"
              r
            end

            # @param font_name [String]
            # @param font_attrs [String]
            # @param font_attrs_map [Hash]
            def render_font_attrs_section(font_name, font_attrs, font_attrs_map)
              sample_prefix = "prefix "
              sample_suffix = "SUFFIX"
              font_attr_prefix, font_attr_suffix = case font_attrs
              when 'bold'
                ["\\textbf{", "}"]
              when 'bold italic'
                ["\\emph{\\textbf{", "}}"]
              when 'italic'
                ["\\emph{", "}"]
              when 'regular'
                ["", ""]
              else
                raise "Handle this: #{ font_attrs.inspect }"
              end

              r = "Kernings for font #{ font_name.inspect }, font attrs #{ font_attrs.inspect }\n\n"
              r << "\\vspace{2em}\n\n"
              r << font_attrs_map.map { |character_pair, kern_val|
                [
                  "\\begin{KerningSample}{\\#{ key_for_font_name(font_name) }}",
                  [
                    "  ",
                    font_attr_prefix,
                    sample_prefix,
                    character_pair[0],
                    "\\RtSmCapsEmulation{#{ character_pair[1].upcase }#{ sample_suffix }}{#{ kern_val }em}",
                    font_attr_suffix,
                    "\\hfill\\textscale{0.5}{#{ kern_val }em}",
                  ].join,
                  "\\end{KerningSample}\n\n",
                ].join("\n")
              }.join
              r << "\\vspace{2em}\n\n"
            end

            # Converts font_name into string that can be used in Latex
            # @param font_name [String]
            # @return [String]
            def key_for_font_name(font_name)
              font_name.downcase.gsub(/[^a-z]+/, '') + 'font'
            end

          end # ClassMethods

        end
      end
    end
  end
end
