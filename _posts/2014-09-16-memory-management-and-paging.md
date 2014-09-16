---
layout: post
title: Memory Management And Paging
---
Memory Management And Paging
================================
I was first introduced to the idea of paging in 6.172, Performance Engineering.
We had to create memory allocators tuned to specific workloads. We made use of
mem_sbrk to allocate underlying pages for use in our memory allocator. But it
stopped at mem_sbrk. All we knew was the the OS took care of the rest.

In a recent lab I did for 6.828, Operating Systems, we had to write another
memory allocator. Unlike the 6.172 version, this was a low-level memory
allocator that actually reserved pages in physical memory.

In x86 systems, physical memory is typically accessed through a memory
management unit (mmu). And the mmu is managed by a two-level page table. Note
that an operating system will typically have user programs interact with
virtual addresses, and all translation to physical memory addresses is done
through the mmu/page table.

The page table that directs the mmu is stored in physical memory. The mmu finds
the table by looking at the CR3 register (control register 3).

Despite calling the whole concept a page table, the physical layout is a bit
more complex. It consists of a page directory with 2^10 = 1024 page tables.
Each page table can in turn hold 2^10 = 1024 entries. And each page represents
2^12 = 4096 bytes. Note that there is a one-to-one correspondence between page
table entry and pages that are possible to address in a 32 bit machine.

A virtual address is formed by combining indices into each of the page
directory, page table, and page. Here is an example 32 bit virtual address:

    0xBA5EBA11 = 10111010010111101011101000010001
                 |________||________||__________|
                   pgdir     pgtbl       page
                   index     index       index

Here is sketch of how the page table looks:

              page directory
    pgdir |  |----------------------------|
    index |  | phys addr of pgtbl | perms | --
          V  |----------------------------|  |
             | phys addr of pgtbl | perms |  |
             |----------------------------|  |
             | ...                        |  |
                                             |
              page table                     |
    pgtbl |  |----------------------------| <-
    index |  | phys addr of page  | perms |
          V  |----------------------------|
             | phys addr of page  | perms | --
             |----------------------------|  |
             | ...                        |  |
                                             |
              page                           |
    page  |  |----------------------------| <-
    index |  | contiguous physical and    |
          V  | and virtual mem            |
             | ...                        |

The operating system keeps a list of free pages in physical memory so that it
can fill in the page table (page directory + page table) appropriately when it
an application asks for more memory.

The mmu is very interesting because it has to read this two-tier structure that
exists in memory each time that it want to translate a virtual address (ie any
address) to a physical address. In order to speed this up the mmu uses a cache
called the translation lookaside buffer (tlb). The tlb caches these mappings.

Whenever the operating system updates the mappings it must also invalidate part
of the tlb.

Last year in 6.172, we were incrementally presented this slide. We were trying
to figure out why the performance degraded so much when `n` gets to 22. The
test code is randomly jumping around some array and incrementing its values.
The size of the array is `1 << n`. So this code is addressing up to 2^22 bytes.

<img src="/images/6172-lec11-storage-allocation.png" style="max-width: 100%; height: auto;"/>

We get to the conclusion that the performance degradation is most likely a
result of tlb misses. The mmu had to go to memory and traverse the two level
page table structure.

This tells us that that the tlb could only hold about 2^21 page table entries.
2^21 continugous bytes represents 2^21 bytes/4096 bytes per page = 512 pages.
And, 2^22 contiguous bytes represents 2^22 bytes/4096 bytes per page = 1024
pages.

Taking a look at the TLB, Intel's Nehalem microarchitecture has a multilevel
tlb. It's largest cache holds just 512 entries (for 4KiB pages). And here is
where we see why the TLB started missing when `n` was bumped to 22.

http://nedbatchelder.com/text/hexwords.html
http://en.wikipedia.org/wiki/Control_register#CR3
http://wiki.osdev.org/Paging
http://www.realworldtech.com/nehalem/8/
