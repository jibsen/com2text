/*
 * dec2t1 - decode c2t1 encoded com file
 *
 * Copyright 2015 Joergen Ibsen
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include <ctype.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define ARRAY_SIZE(arr) (sizeof(arr) / sizeof((arr)[0]))

static const uint8_t handler[] = {
	0x58, 0x35, 0x30, 0x32, 0x35, 0x30, 0x33, 0x50, 0x5F, 0x35,
	0x3A, 0x53, 0x29, 0x45, 0x38, 0x2C, 0x77, 0x50, 0x2D, 0x51,
	0x5F, 0x50, 0x35, 0x72, 0x33, 0x35, 0x3B, 0x34, 0x50, 0x2D,
	0x2B, 0x4A, 0x50, 0x35, 0x4A, 0x53, 0x2D, 0x57, 0x24, 0x50,
	0x68, 0x6B, 0x78, 0x68, 0x2D, 0x6B, 0x2D, 0x24, 0x27, 0x24,
	0x5E, 0x50, 0x54, 0x58, 0x53, 0x57, 0x39, 0x23
};

struct state {
	const uint8_t *src;
	uint8_t *dst;
	size_t src_size;
	size_t dst_size;
	uint8_t low_nibble;
	int have_low_nibble;
};

/*
 * Get next 4-bit value.
 *
 * Returns 0 on success, 1 on end of data, -1 on error.
 */
static int
get_next_val(struct state *s, uint8_t *pv)
{
	uint8_t c;

	/* Skip whitespace */
	while (s->src_size > 0 && isspace(*s->src)) {
		++s->src;
		--s->src_size;
	}

	if (s->src_size == 0) {
		return 1;
	}

	c = *s->src++;
	--s->src_size;

	if (c >= 'k' && c <= 'z') {
		*pv = c - 'k';
		return 0;
	}

	return -1;
}

/**
 * Decode data in state.
 *
 * Returns 0 on success, 1 on end of data, -1 on error.
 */
static int
decode(struct state *s)
{
	int res = -1;

	for (;;) {
		uint8_t c = 0;

		if (s->have_low_nibble == 0) {
			res = get_next_val(s, &s->low_nibble);
			if (res != 0) {
				return res;
			}
			s->have_low_nibble = 1;
		}

		res = get_next_val(s, &c);
		if (res != 0) {
			return res;
		}

		c = (c << 4) | s->low_nibble;
		s->have_low_nibble = 0;

		*s->dst++ = c;
		++s->dst_size;
	}
}

int
main(int argc, char **argv)
{
	uint8_t src[256];
	uint8_t dst[256];
	struct state s;
	FILE *infile = NULL;
	FILE *outfile = NULL;
	size_t n_read;
	int res = EXIT_FAILURE;

	if (argc < 3) {
		printf("Syntax: dec2t1 <infile> <outfile>\n");
		return EXIT_FAILURE;
	}

	infile = fopen(argv[1], "rb");
	if (infile == NULL) {
		printf("ERR: unable to open input file\n");
		goto out;
	}

	outfile = fopen(argv[2], "w+b");
	if (outfile == NULL) {
		printf("ERR: unable to open output file\n");
		goto out;
	}

	s.have_low_nibble = 0;

	n_read = fread(src, 1, ARRAY_SIZE(handler), infile);

	if (n_read != ARRAY_SIZE(handler)
	 || memcmp(src, handler, ARRAY_SIZE(handler)) != 0) {
		printf("ERR: handler mismatch\n");
		goto out;
	}

	while ((n_read = fread(src, 1, ARRAY_SIZE(src), infile)) > 0) {
		s.src = src;
		s.dst = dst;
		s.src_size = n_read;
		s.dst_size = 0;

		if (decode(&s) == -1) {
			printf("ERR: decode error\n");
			goto out;
		}

		if (fwrite(dst, 1, s.dst_size, outfile) != s.dst_size) {
			printf("ERR: error writing\n");
			goto out;
		}
	}

	printf("Everything appears to be okay.\n");
	res = EXIT_SUCCESS;

out:
	if (outfile != NULL) {
		fclose(outfile);
	}
	if (infile != NULL) {
		fclose(infile);
	}

	return res;
}
