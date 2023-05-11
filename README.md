# Primal - the Operating System / Application Environment for Z80 based computers

Primal is another Operating System / Application Environment for Z80 based computers.  

What are the goals of Primal?

1. To increase the potential audience for an application developer by utilising a single code-base that can run on multiple platforms.
2. To provide new software for systems that are rarely getting any new software.


Aren't there already Operating Systems that can run on multiple platforms?

Yes, many.  Examples include flavours of CP/M, Symbos, RomWBW, Z-Machine and others. But a single application run on all these?  Not usually unless it is recompiled, but the Z-Machine is likely the closest thing.


So, Primal has something new?

Probably not, not sure... You could argue that Primal is to do what a Z-Machine does but in a different way.  Z-Machine is a virtual machine and was used to create text adventure games.  Primal is created for any types of applications and is not a virtual machine.


How does Primal Work?

Primal is an Operating System which has a Multi-Level API.  The Operating System itself can run natively on hardware, but can also run it as an application environment on top of existing host Operating Systems.  An application developed for Primal is unaware of the difference so if you develop an application for Primal, it can suddenly work on many other platforms which otherwise wouldn't be.  


So, What platforms are supported by Primal?

The first batch of target platforms that Primal is being developed for are as follows, however a few of them it is very difficult to find developer documentation, so if they get completed, time will tell:

Target Platform Batch 1:

- Amstrad CPC (hosts: AMSDOS / FutureOS / CPM 2.2) <--- our reference large memory system
- Coleco Adam (host: EOS)
- CP/M 2.2 & CP/M Plus as a host
- Enterprise 128 (host: EXDOS)
- MSXDOS as a host
- RomWBW as a host
- Sega SC3000 (host: BASIC / DiskBASIC)
- Symbos as a host
- Tandy TRS-80 (host: TRSDOS)
- Tatung Einstein (host: MOS)
- Zx Spectrum 16k <--- our reference small memory system
- Zx Spectrum+
- Zx Spectrum +2
- Zx Spectrum +3


Multi-Level API?

Yes, that is what it is called.  Primal is broken down into various components as follows:

LOADER:  API Level 1. The loader is the lowest level and provides 'a little bit more' than what is needed minimally to allow text console type applications to run.  As everyone knows, when you start developing, features creep in, so this happened to the loader which started as simply a way to load an application and provide a platform independent way (from the application point of view) to get keyboard input and output to the console.  Now loader does that, but also some memory management too and has some functions to facilitate (but not provide) virtual memory support.  Loader needs to be useful enough but also stay small enough for some very small target platforms - didn't you see a Zx Spectrum 16K above?  Consider this our reference small memory system.  Loader is about 50% platform specific so a new one needs to be created for each new platform.

MEM:  API Level 2. The mem (or memory) component could have been included within loader, but separating it allowed for a couple of benefits.  A small memory system could choose a smaller footprint if they only required the Level 1 API, but also platforms where there are multiple memory models available can have alternate mem components that can be chosen at run-time.  For example an Amstrad CPC might have 64k or 128k as base models but might also have an additional 256k, 512k, 1024k or 4096k of memory available.  So a variety of mem components are built.  Virtual memory is supported.  Mem is mostly platform specific so new onces can be created, but the generic 'none' mem component is provided for systems that do not have extra memory.

BIOS:  API Level 3.  Not a lot has been developed here yet, still in the design phase.  It is inteded that a driver model will be introduced here so that the BIOS for most part itself will be platform independent but facilitate platform dependant drivers.

KERNEL:  API Level 4.  We start getting into some of the higher level parts of the operating system here.  100% platform independent kernel details to come.  This level and every high level should be platform independent.

SHELL:  API Level 5.  More details to come.


A lot is not finished, can I do anything with it yet?

ALMOST... as of May 2023, the first couple of platforms have almost been completed ready for testing.  The rest of Target Platform Batch 1 is in various states of completeness.

- Julian
