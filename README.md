# MIT-MC CP/M archive files, 1979-1984 
This repository contains code, software, and related files developed for the [CP/M operating system](https://en.wikipedia.org/wiki/CP/M), created from 1979-1984. It was hosted on the Massachusetts Institute of Technology's MIT-MC (Macsyma Consortium) computer and available on the ARPANET. This was a freeware and shareware "archive" maintained by Frank J. Wancho and Keith Petersen. When the Macsyma Consortium was dissolved in 1983, the files were moved to [SIMTEL20](https://www.cni.org/resources/historical-resources/farnet-stories-project/geographical-index/story149.NM). The files available in this repo are a part of the [Massachusetts Institute of Technology, Tapes of Tech Square (ToTS) collection](https://archivesspace.mit.edu/repositories/2/resources/1265) at the MIT Libraries Department of Distinctive Collections (DDC).
## File organization and details
### [cpm](../main/cpm)
The files within this directory are the CP/M archive specific files from [24 different tape image files](../main/tapeimagelist.txt) in the [ToTS collection](https://archivesspace.mit.edu/repositories/2/resources/1265). Files are from ITS backup tapes. Files were stored on a PDP-10 timeshare computer running the ITS operating system.

Files were extracted from the tape images using the [itstar program](https://github.com/PDP-10/itstar). The filenames have been adapted to Unix conventions, as per the itstar translation. The original filename syntax would be formatted like, `FJW; LMODEM 258`, for example. All files have been placed into this artificial `cpm` directory for organizational purposes. The files extracted from the tape images were put into sub-folders with a corresponding name to the tapes listed in the `tapeimagelist.txt` file.

[221 files are ITS archive files](../main/ITSarchivefilelist.txt) within this extracted set. Digital Archivist, Joe Carrano, extracted the contents of these files into directories of the same name, one level up from their location using the [itsarc](https://github.com/larsbrinkhoff/pdp10-its-disassembler/blob/master/itsarc.c) program. The program replaced the `/` with a `{` in the filname of [`cpm/7005964/ar13.news/sig{m.jun81`](../main/cpm/7005964/ar13.news/sig{m.jun81). It also added the `~` in place of spaces in [`cpm/7005964/ar2.hlpfil/<urhlp.~~~~~7`](../main/cpm/7005964/ar2.hlpfil/<urhlp.~~~~~7). 
### [codemeta.json](../main/codemeta.json)
This file is metadata about the CP/M archive files, using the [CodeMeta Project](https://codemeta.github.io/) schema.
### [README.md](../main/README.md)
This file is the readme detailing the content and context for this repository.
### [tree.txt](../main/tree.txt)
A file tree listing the files in the [cpm](../main/cpm) directory showing the original file timestamps as extracted from the tape images. The [`cpm/7005176/cpm/ar66.micnet`](../main/cpm/7005176/cpm/ar66.micnet) file timestamp did not extract properly. Within the ITS archive files mentioned above, `sig{m.jun81` filename replacement caused the modified date to be adjusted. `<urhlp.~~~~~7` file has a timestamp that is not recognized properly. All of these files are most likely from the same date range as the rest of the files. 
### [tapeimagelist.txt](../main/tapeimagelist.txt)
A list of all the tape images and their paths in the ToTS collection that these files came from.
### [ITSarchivefilelist.txt](../main/ITSarchivefilelist.txt)
A list of all the ITS archive files and their paths in this repo.
## Preferred Citation
[filename], MIT-MC CP/M archive files, 1979-1984, Massachusetts Institute of Technology, Tapes of Tech Square (ToTS) collection, MC-0741. Massachusetts Institute of Technology, Department of Distinctive Collections, Cambridge, Massachusetts.
## Rights
[These items may be under copyright](https://rightsstatements.org/page/CNE/1.0/). Please consult the collection finding aid or catalog record and the [MIT Libraries Permissions Policy](https://libraries.mit.edu/about/policies/copyright-permissions-policy/) for more information. Any questions about permissions should be directed to [permissions-lib@mit.edu](mailto:permissions-lib@mit.edu)
## Acknowledgements
Thanks to [Lars Brinkhoff](https://github.com/larsbrinkhoff) for help with identifying these files.