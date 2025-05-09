export default {
	async fetch(request: Request): Promise<Response> {
		const url = new URL(request.url);
		const path = url.pathname;

		const domainName = path.substring(1);
		if (!domainName) {
			return new Response('', {
				status: 400,
			});
		}

		try {
			const githubUrl = `https://raw.githubusercontent.com/LoV432/pta-block/refs/heads/master/domains/${domainName}`;
			const response = await fetch(githubUrl);

			if (!response.ok) {
				return new Response('', {
					status: 404,
				});
			}

			const content = await response.text();
			return new Response(content, {
				headers: {
					'Content-Type': 'text/plain',
				},
			});
		} catch (error) {
			return new Response('', {
				status: 500,
			});
		}
	},
} satisfies ExportedHandler<Env>;
