# Replace Uses

A small Delphi console application to replace units in the uses clauses, to help get rid of unit scopes in your old Delphi projects.

## How to use, in a nutshell

(See further down for more details)

- Modify `ReplaceUses.ini` to match your environment
- Compile and run
- Manually remove the unit scopes from the updated projects (check all revelant targets)

## Context

I wrote this after reading Marco Cantú's blog post ["Some suggestions to help the Delphi compiler"](https://blog.marcocantu.com/blog/2022-december-suggestions-help-delphi-compiler.html)(dec 2022).

In it, he describes the potential improvement on compilation time, if you get rid of [_unit aliases_](https://docwiki.embarcadero.com/RADStudio/Sydney/en/Delphi_Compiler) and [_unit scopes_](https://docwiki.embarcadero.com/RADStudio/Sydney/en/Unit_Scope_Names).

Especially unit scopes can be a lot of work. You'll find these in older projects (Delphi 7 and before). To better categorise units names, the short names of old were renamed to longer, dotted names. `Forms` became `Vcl.Forms`, and `AdoDB` became `Win.DB.AdoDB`.

The IDE can help you a bit; hovering a unit name gives you the fully qualified name, and GExperts apparently can [fix the uses clause of the current unit](https://en.delphipraxis.net/topic/1843-ide-addin-to-automatically-add-fully-qualified-namespace-to-uses-clause-unit-names-and-variable-type-declarations/).

Where tool is different, is that it can do this for a whole project, or rather for a folder or list of folders.
The codebase I needed this for is large. Started in 2004 as an offspring of an even older project, it has become hundreds of thousands of lines over thousands of units, spread over packages, frameworks, applications and test projects.

So I wanted to have a tool that could do all that at once.

## Configuration

The tool can be configured using an inifile containing 3 sections, where you can set which directories to be searched (toplevel only or recursively), and which unit names to replace.

```ini
[TopLevel]
; Folders to be searched for pas files, no sub-folders. No key=value, just folder names

[Recursive]
; Folders to be searched for pas files, including sub-folders x=Folder. No key=value, just folder names
C:\Dev\Delphi\MyApplication
C:\Dev\Delphi\MyLibraries

[Uses]
; Searches in the uses clauses. Unit=Replacement
DB=Data.DB
DBByteBuffer=Data.DBByteBuffer
DBCommon=Data.DBCommon
```

The inifile already contains a big list, which is effectively a trimmed down version of the [Delphi XE2 Unit Scope tables](https://wiert.me/2011/11/17/delphi-xe2-unit-scope-tables/) documented by Jeroen Wiert Pluimers, with duplicates removed.

## Considerations/warnings

- Make a backup/push your changes before you start

- Start with a small folder to see if it does what you expect. Something that can easily be reverted using your backup of version control system.

- This tool is crude, not a fully fledged application

  - It _does not alter or remove_ your project's unit aliases or unit scopes. You will still have to that manually, although that's little work compared to all the replacements.
  - It _does not use_ your existing unit scopes.

    For example `Consts` could become `MacApi.Consts` or `Vcl.Consts`. The tool is not smart in this regard. Currently you can define only one entry for `Consts` (having multiple will throw an error), and you have to set it to the right replacement for you.

    The current list can be considered 'mostly Win 32 VCL', and will probably do for most old projects. If your project targets a different platform, you may have to update the inifile.

    If your project targets multiple platforms, you may want to keep the unit scopes that are different per build target, or otherwise you may need some defines in the unit clauses to deal with this.

- Your mileage may vary. With 5000 replacements in my project, I expected to see at least some impact, but I couldn't measure any improvement.

- Libraries can give a problem. Using their DCUs is the best option for speed anyway, but if for whatever reason you do compile their sources as part of your project, this will fail if they still rely on unit scopes.
