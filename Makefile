# XXX patch /usr/ports/Mk/Uses/go.mk line 135, GO_WRKSRC= -> GO_WRKSRC?=

PORTNAME=	focalboard
DISTVERSIONPREFIX=	v
DISTVERSION=	7.9.3
CATEGORIES=	sysutils
MASTER_SITES=	LOCAL/mikael:npm \
		https://raw.githubusercontent.com/mattermost/focalboard/v7.9.3/server/:gomod
DISTFILES=	focalboard-${DISTVERSION}-npm-cache.tar.gz:npm \
		go.mod:gomod

MAINTAINER=	mikael@FreeBSD.org
COMMENT=	Self-hosted alternative to Trello, Notion, and Asana
WWW=		https://www.focalboard.com/

#LICENSE=	APACHE20 AGPLv3 APACHE20 MIT
#LICENSE_FILE=	${WRKSRC}/LICENSE.txt

BUILD_DEPENDS=	npm:www/npm-node16 \
		autoconf:devel/autoconf \
		automake:devel/automake \
		libtool:devel/libtool \
		nasm:devel/nasm

USES=		gmake go:modules
USE_GITHUB=	yes
GH_ACCOUNT=	mattermost

GO_MODULE=	github.com/mattermost/focalboard/server
GO_WRKSRC=	${WRKSRC}/server

MAKE_ENV+=	EXCLUDE_PLUGIN=true \
		EXCLUDE_SERVER=true \
		EXCLUDE_ENTERPRISE=true \

# XXX fix BuildNumber, BuildDate, BuidlHash
GO_FLAGS=	-buildvcs=false \
		-ldflags '\
		-X "github.com/mattermost/focalboard/server/model.BuildNumber=${DISTVERSION}" \
		-X "github.com/mattermost/focalboard/server/model.BuildDate=2023" \
		-X "github.com/mattermost/focalboard/server/model.BuildHash=1e407f93c0f26951c54f6bca57cb65f2e5eb526a"' \
		-tags 'json1 sqlite3' -o ../bin/freebsd/focalboard-server ./main

NPM_TIMESTAMP=	1661146515

fetch-npm:
	if [ ! -f ${DISTDIR}/${PORTNAME}-${DISTVERSION}-npm-cache.tar.gz ]; then \
		${MKDIR} /tmp/${PORTNAME}/webapp /tmp/${PORTNAME}/mattermost-plugin/webapp; \
		cd /tmp/${PORTNAME}; \
		${FETCH_CMD} -o webapp  https://raw.githubusercontent.com/mattermost/focalboard/v${DISTVERSION}/webapp/package.json; \
		${FETCH_CMD} -o webapp  https://raw.githubusercontent.com/mattermost/focalboard/v${DISTVERSION}/webapp/package-lock.json; \
		${FETCH_CMD} -o mattermost-plugin/webapp  https://raw.githubusercontent.com/mattermost/focalboard/v${DISTVERSION}/mattermost-plugin/webapp/package.json; \
		${FETCH_CMD} -o mattermost-plugin/webapp  https://raw.githubusercontent.com/mattermost/focalboard/v${DISTVERSION}/mattermost-plugin/webapp/package-lock.json; \
		cd /tmp/${PORTNAME}/webapp && ${SETENV} HOME=/tmp/${PORTNAME} XDG_CACHE_HOME=/tmp/${PORTNAME}/.cache \
			npm ci --ignore-scripts; \
		cd /tmp/${PORTNAME}/mattermost-plugin/webapp && ${SETENV} HOME=/tmp/${PORTNAME} XDG_CACHE_HOME=/tmp/${PORTNAME}/.cache \
			npm ci --ignore-scripts; \
		cd /tmp/${PORTNAME} && ${RM} -r mattermost-plugin webapp; \
		${MTREE_CMD} -cbnS | ${MTREE_CMD} -C | ${SED} \
			-e 's:time=[0-9.]*:time=${NPM_TIMESTAMP}.000000000:' \
			-e 's:\([gu]id\)=[0-9]*:\1=0:g' \
			-e 's:flags=.*:flags=none:' \
			-e "s:^\.:./${PORTNAME}:" > /tmp/npm-offline-cache.mtree; \
		${TAR} cJf ${DISTDIR}/${PORTNAME}-${DISTVERSION}-npm-cache.tar.gz \
			@/tmp/npm-offline-cache.mtree; \
	fi

post-extract:
	# XXX fix fetch-npm
	${MV} ${WRKDIR}/focalboard/.npm ${WRKDIR}

post-patch:
	${REINPLACE_CMD} 's#ETCDIR#${ETCDIR}#' \
		${WRKSRC}/server/services/config/config.go
	${REINPLACE_CMD} 's#DATADIR#${DATADIR}#' \
		${WRKSRC}/config.json

# https://github.com/mattermost/focalboard/#contribute-to-focalboard
do-build:
	cd ${WRKSRC} && ${SETENV} ${MAKE_ENV} ${MAKE_CMD} prebuild
	cd ${WRKSRC} && ${SETENV} ${MAKE_ENV} ${MAKE_CMD} webapp
	cd ${WRKSRC}/server && ${SETENV} ${MAKE_ENV} GOENV="${GO_ENV}" go build ${GO_FLAGS}

do-install:
	${MKDIR} ${STAGEDIR}${ETCDIR} \
		 ${STAGEDIR}${DATADIR}/webapp/pack
	${INSTALL_PROGRAM} ${WRKSRC}/bin/freebsd/focalboard-server ${STAGEDIR}${PREFIX}/bin
	${CP} ${WRKSRC}/config.json ${STAGEDIR}${ETCDIR}/config.json.sample
	cd ${WRKSRC}/webapp/pack && ${COPYTREE_SHARE} . ${STAGEDIR}${DATADIR}/webapp/pack

.include <bsd.port.mk>
