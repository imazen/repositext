module Kramdown
  module Converter
    class LatexRepositext
      class SmallcapsKerningMap
        # Namespace for methods related to generating a kerning samples PDF document.
        module KerningSampleLatexMixin

          extend ActiveSupport::Concern

          # Namespace for class methods
          module ClassMethods

            # Returns latex for generating the kerning sample document
            def kerning_sample_latex
              kerning_map = new.kerning_map
              kerning_values_map = kerning_map['kerning_values']
              font_names = kerning_values_map.keys
              character_mappings = kerning_map['character_mappings']
              smcaps_emulator = LatexRepositext.send(:new, '_', {})
              latex = render_latex_prefix(font_names)
              latex << render_latex_body(kerning_values_map, character_mappings, smcaps_emulator)
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
% first argument: leading kerning adjustment, inserted before the smallcaps text. Provide 'none' for no kerning.
% second argument: the text to render in smallcaps.
% third argument: trailing kerning adjustment, inserted after the smallcaps text. Provide 'none' for no kerning.
\\newcommand{\\RtSmCapsEmulation}[3]
  {%
    \\ifthenelse{\\equal{#1}{none}}%
      {}%
      {\\hspace{#1}}%
    \\textscale{0.7}{#2}%
    \\ifthenelse{\\equal{#3}{none}}%
      {}%
      {\\hspace{#3}}%
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
            # @param smcaps_emulator [Kramdown::Converter::LatexRepositext]
            def render_latex_body(kerning_values_map, character_mappings, smcaps_emulator)
              kerning_values_map.map { |font_name, font_name_map|
                render_font_name_section(font_name, font_name_map, smcaps_emulator)
              }.join
            end

            def render_latex_suffix
              %(\n\\end{document})
            end

            # @param font_name [String]
            # @param font_name_map [Hash]
            # @param smcaps_emulator [Kramdown::Converter::LatexRepositext]
            def render_font_name_section(font_name, font_name_map, smcaps_emulator)
              r = [
                "\\begin{KerningSample}{\\#{ key_for_font_name(font_name) }}",
                font_name,
                "\\end{KerningSample}\n",
                "\\vspace{2em}\n\n",
              ].join("\n")
              r << font_name_map.map { |font_attrs, font_attrs_map|
                render_font_attrs_section(font_name, font_attrs, font_attrs_map, smcaps_emulator)
              }.join
              r << "\\newpage\n\n"
              r
            end

            # @param font_name [String]
            # @param font_attrs [String]
            # @param font_attrs_map [Hash]
            # @param smcaps_emulator [Kramdown::Converter::LatexRepositext]
            def render_font_attrs_section(font_name, font_attrs, font_attrs_map, smcaps_emulator)
              sample_prefix = "prefix"
              sample_suffix = "suffix"
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
              # Partition character pairs, put the ones with null kerning values at the top.
              cps_without_kern_val, cps_with_kern_val = font_attrs_map.partition { |character_pair, kern_val|
                kern_val.nil?
              }
              all_cps = cps_without_kern_val + cps_with_kern_val # join them with null kerns at the front
              r << all_cps.map { |character_pair, kern_val|
                txt = case character_pair
                when /[[:upper:]][[:lower:]]/
                  [sample_prefix, ' ', character_pair, sample_suffix].join
                when /[[:lower:]][^[:alpha:]]/
                  [sample_prefix, character_pair, ' ', sample_suffix].join
                when /[[:lower:]][[:upper:]]/
                  [sample_prefix, character_pair, sample_suffix].join
                else
                  raise "Handle this: #{ character_pair.inspect }"
                end
                smcaps_emulated_latex = smcaps_emulator.emulate_small_caps(
                  txt,
                  font_name,
                  font_attrs.split(' ')
                )
                [
                  "\\begin{KerningSample}{\\#{ key_for_font_name(font_name) }}",
                  "\\rule[-.3\\baselineskip]{0pt}{\\baselineskip}%", # Insert strut to avoid inconsistent vertical spacing caused by different height characters.
                  [
                    "  ",
                    font_attr_prefix,
                    smcaps_emulated_latex,
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
