# Copyright Leandro Lucarella 2006 - 2014
# Distributed under the Boost Software License, Version 1.0
# See the LICENSE file for details, or http://www.boost.org/LICENSE_1_0.txt

.PHONY: example
example:
	@$(MAKE) -C example

.PHONY: clean-example
clean-example:
	@$(MAKE) -C example clean

